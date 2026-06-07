"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createInvoiceFromEstimate = exports.createInvoiceFromJobCard = exports.getNextJobCardNumber = exports.getNextInvoiceNumber = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/https");
admin.initializeApp();
const db = admin.firestore();
async function vehicleNumberInTransaction(tx, vehicleId) {
    const vehicleSnap = await tx.get(db.doc(`vehicles/${vehicleId}`));
    if (!vehicleSnap.exists) {
        return "Unknown vehicle";
    }
    return vehicleSnap.data()?.regNumber ?? "Unknown vehicle";
}
async function deductPartsStock(tx, partsItems, invoiceRef) {
    let partsTotal = 0;
    for (const part of partsItems) {
        const stockRef = db.doc(`stock_items/${part.stockItemId}`);
        const stockSnap = await tx.get(stockRef);
        if (!stockSnap.exists) {
            throw new https_1.HttpsError("not-found", `Stock item ${part.stockItemId} missing`);
        }
        const currentStock = stockSnap.data()?.currentStock ?? 0;
        if (currentStock < part.qty) {
            throw new https_1.HttpsError("failed-precondition", `Insufficient stock for ${part.name}`);
        }
        tx.update(stockRef, { currentStock: currentStock - part.qty });
        tx.set(db.collection("stock_transactions").doc(), {
            stockItemId: part.stockItemId,
            type: "out",
            qty: part.qty,
            referenceType: "invoice",
            referenceId: invoiceRef.id,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        partsTotal += part.amount;
    }
    return partsTotal;
}
exports.getNextInvoiceNumber = (0, https_1.onCall)(async () => {
    const settingsRef = db.doc("settings/garage");
    return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(settingsRef);
        const current = snapshot.exists ? snapshot.data()?.nextInvoiceNumber ?? 1 : 1;
        tx.set(settingsRef, { nextInvoiceNumber: current + 1 }, { merge: true });
        return { invoiceNumber: current };
    });
});
exports.getNextJobCardNumber = (0, https_1.onCall)(async () => {
    const settingsRef = db.doc("settings/garage");
    return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(settingsRef);
        const current = snapshot.exists ? snapshot.data()?.nextJobCardNumber ?? 900 : 900;
        tx.set(settingsRef, { nextJobCardNumber: current + 1 }, { merge: true });
        return { jobCardNumber: current };
    });
});
exports.createInvoiceFromJobCard = (0, https_1.onCall)(async (request) => {
    const payload = request.data;
    if (!payload.jobCardId) {
        throw new https_1.HttpsError("invalid-argument", "jobCardId is required");
    }
    const labourItems = payload.labourItems ?? [];
    const partsItems = payload.partsItems ?? [];
    const amountPaid = payload.amountPaid ?? 0;
    const paymentStatus = payload.paymentStatus ?? "unpaid";
    const settingsRef = db.doc("settings/garage");
    const jobCardRef = db.doc(`jobcards/${payload.jobCardId}`);
    const invoiceRef = db.collection("invoices").doc();
    const result = await db.runTransaction(async (tx) => {
        const [settingsSnap, jobCardSnap] = await Promise.all([
            tx.get(settingsRef),
            tx.get(jobCardRef),
        ]);
        if (!jobCardSnap.exists) {
            throw new https_1.HttpsError("not-found", "Job card not found");
        }
        const jobCard = jobCardSnap.data();
        const invoiceNumber = settingsSnap.exists ?
            settingsSnap.data()?.nextInvoiceNumber ?? 1 :
            1;
        const partsTotal = await deductPartsStock(tx, partsItems, invoiceRef);
        const labourTotal = labourItems.reduce((sum, item) => sum + item.amount, 0);
        const grandTotal = labourTotal + partsTotal;
        const vehicleNumber = await vehicleNumberInTransaction(tx, jobCard.vehicleId);
        tx.set(invoiceRef, {
            invoiceNumber,
            jobCardId: payload.jobCardId,
            customerId: jobCard.customerId,
            vehicleId: jobCard.vehicleId,
            vehicleNumber,
            kmReading: jobCard.kmReading,
            labourItems,
            partsItems,
            labourTotal,
            partsTotal,
            grandTotal,
            amountPaid,
            paymentStatus,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.update(jobCardRef, { status: "delivered" });
        tx.set(settingsRef, { nextInvoiceNumber: invoiceNumber + 1 }, { merge: true });
        return { invoiceId: invoiceRef.id, invoiceNumber, grandTotal };
    });
    return result;
});
exports.createInvoiceFromEstimate = (0, https_1.onCall)(async (request) => {
    const payload = request.data;
    if (!payload.estimateId) {
        throw new https_1.HttpsError("invalid-argument", "estimateId is required");
    }
    const settingsRef = db.doc("settings/garage");
    const estimateRef = db.doc(`estimates/${payload.estimateId}`);
    const invoiceRef = db.collection("invoices").doc();
    const result = await db.runTransaction(async (tx) => {
        const [settingsSnap, estimateSnap] = await Promise.all([
            tx.get(settingsRef),
            tx.get(estimateRef),
        ]);
        if (!estimateSnap.exists) {
            throw new https_1.HttpsError("not-found", "Estimate not found");
        }
        const estimate = estimateSnap.data();
        if (estimate.status === "converted") {
            throw new https_1.HttpsError("failed-precondition", "Estimate already converted");
        }
        const invoiceNumber = settingsSnap.exists ?
            settingsSnap.data()?.nextInvoiceNumber ?? 1 :
            1;
        const labourItems = estimate.labourItems ?? [];
        const partsItems = estimate.partsItems ?? [];
        const partsTotal = await deductPartsStock(tx, partsItems, invoiceRef);
        const labourTotal = labourItems.reduce((sum, item) => sum + item.amount, 0);
        const grandTotal = labourTotal + partsTotal;
        tx.set(invoiceRef, {
            invoiceNumber,
            jobCardId: estimate.jobCardId ?? null,
            customerId: estimate.customerId,
            vehicleId: estimate.vehicleId,
            vehicleNumber: estimate.vehicleNumber,
            kmReading: estimate.kmReading,
            labourItems,
            partsItems,
            labourTotal,
            partsTotal,
            grandTotal,
            amountPaid: 0,
            paymentStatus: "unpaid",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.update(estimateRef, { status: "converted" });
        if (estimate.jobCardId) {
            tx.update(db.doc(`jobcards/${estimate.jobCardId}`), { status: "delivered" });
        }
        tx.set(settingsRef, { nextInvoiceNumber: invoiceNumber + 1 }, { merge: true });
        return { invoiceId: invoiceRef.id, invoiceNumber, grandTotal };
    });
    return result;
});
//# sourceMappingURL=index.js.map