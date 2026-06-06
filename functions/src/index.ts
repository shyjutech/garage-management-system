import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/https";

admin.initializeApp();

const db = admin.firestore();

type LabourItem = {description: string; amount: number};
type PartsItem = {
  stockItemId: string;
  name: string;
  qty: number;
  unitPrice: number;
  amount: number;
};

async function vehicleNumberInTransaction(
  tx: admin.firestore.Transaction,
  vehicleId: string,
): Promise<string> {
  const vehicleSnap = await tx.get(db.doc(`vehicles/${vehicleId}`));
  if (!vehicleSnap.exists) {
    return "Unknown vehicle";
  }
  return (vehicleSnap.data()?.regNumber as string | undefined) ?? "Unknown vehicle";
}

async function deductPartsStock(
  tx: admin.firestore.Transaction,
  partsItems: PartsItem[],
  invoiceRef: admin.firestore.DocumentReference,
) {
  let partsTotal = 0;
  for (const part of partsItems) {
    const stockRef = db.doc(`stock_items/${part.stockItemId}`);
    const stockSnap = await tx.get(stockRef);
    if (!stockSnap.exists) {
      throw new HttpsError("not-found", `Stock item ${part.stockItemId} missing`);
    }
    const currentStock = stockSnap.data()?.currentStock ?? 0;
    if (currentStock < part.qty) {
      throw new HttpsError("failed-precondition", `Insufficient stock for ${part.name}`);
    }
    tx.update(stockRef, {currentStock: currentStock - part.qty});
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

export const getNextInvoiceNumber = onCall(async () => {
  const settingsRef = db.doc("settings/garage");
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(settingsRef);
    const current = snapshot.exists ? snapshot.data()?.nextInvoiceNumber ?? 1 : 1;
    tx.set(settingsRef, {nextInvoiceNumber: current + 1}, {merge: true});
    return {invoiceNumber: current};
  });
});

export const getNextJobCardNumber = onCall(async () => {
  const settingsRef = db.doc("settings/garage");
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(settingsRef);
    const current = snapshot.exists ? snapshot.data()?.nextJobCardNumber ?? 900 : 900;
    tx.set(settingsRef, {nextJobCardNumber: current + 1}, {merge: true});
    return {jobCardNumber: current};
  });
});

export const createInvoiceFromJobCard = onCall(async (request) => {
  const payload = request.data as {
    jobCardId?: string;
    labourItems?: LabourItem[];
    partsItems?: PartsItem[];
    amountPaid?: number;
    paymentStatus?: "paid" | "unpaid" | "partial";
  };

  if (!payload.jobCardId) {
    throw new HttpsError("invalid-argument", "jobCardId is required");
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
      throw new HttpsError("not-found", "Job card not found");
    }

    const jobCard = jobCardSnap.data()!;
    const invoiceNumber = settingsSnap.exists ?
      settingsSnap.data()?.nextInvoiceNumber ?? 1 :
      1;

    const partsTotal = await deductPartsStock(tx, partsItems, invoiceRef);
    const labourTotal = labourItems.reduce((sum, item) => sum + item.amount, 0);
    const grandTotal = labourTotal + partsTotal;
    const vehicleNumber = await vehicleNumberInTransaction(
      tx,
      jobCard.vehicleId as string,
    );

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

    tx.update(jobCardRef, {status: "delivered"});
    tx.set(settingsRef, {nextInvoiceNumber: invoiceNumber + 1}, {merge: true});

    return {invoiceId: invoiceRef.id, invoiceNumber, grandTotal};
  });

  return result;
});

export const createInvoiceFromEstimate = onCall(async (request) => {
  const payload = request.data as {estimateId?: string};
  if (!payload.estimateId) {
    throw new HttpsError("invalid-argument", "estimateId is required");
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
      throw new HttpsError("not-found", "Estimate not found");
    }

    const estimate = estimateSnap.data()!;
    if (estimate.status === "converted") {
      throw new HttpsError("failed-precondition", "Estimate already converted");
    }

    const invoiceNumber = settingsSnap.exists ?
      settingsSnap.data()?.nextInvoiceNumber ?? 1 :
      1;

    const labourItems = (estimate.labourItems as LabourItem[] | undefined) ?? [];
    const partsItems = (estimate.partsItems as PartsItem[] | undefined) ?? [];
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

    tx.update(estimateRef, {status: "converted"});

    if (estimate.jobCardId) {
      tx.update(db.doc(`jobcards/${estimate.jobCardId}`), {status: "delivered"});
    }

    tx.set(settingsRef, {nextInvoiceNumber: invoiceNumber + 1}, {merge: true});

    return {invoiceId: invoiceRef.id, invoiceNumber, grandTotal};
  });

  return result;
});
