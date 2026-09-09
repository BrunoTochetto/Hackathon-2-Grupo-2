const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger que escuta novas inserções na subcoleção movements
 * Atualiza atomicamente a contagem de clientes/alunos no estabelecimento.
 */
exports.onMovementRecorded = functions.firestore
  .document("establishments/{establishmentId}/movements/{movementId}")
  .onCreate(async (snap, context) => {
    const { establishmentId } = context.params;
    const movementData = snap.data();
    const delta = movementData.delta || 0;

    const establishmentRef = db.collection("establishments").doc(establishmentId);

    try {
      await db.runTransaction(async (transaction) => {
        const estDoc = await transaction.get(establishmentRef);
        if (!estDoc.exists) return;

        const currentGuests = estDoc.data().currentGuests || 0;
        const newCount = Math.max(0, currentGuests + delta);

        transaction.update(establishmentRef, {
          currentGuests: newCount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      console.log(`[SmartBuffet] Movimento atualizado no estabelecimento ${establishmentId}: +(${delta})`);
    } catch (error) {
      console.error("[SmartBuffet] Erro ao atualizar contagem de movimento:", error);
    }
  });

/**
 * Consolidação diária automática (Executada às 23:59 todos os dias)
 * Agrupa produção, sobras registradas e calcula economia e desperdício evitado.
 */
exports.consolidateDailyHistory = functions.pubsub
  .schedule("59 23 * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async (context) => {
    const establishmentsSnap = await db.collection("establishments").get();

    for (const estDoc of establishmentsSnap.docs) {
      const estId = estDoc.id;
      const estData = estDoc.data();
      const expectedGuests = estData.expectedGuests || 0;
      const attendedGuests = estData.currentGuests || 0;

      // Busca desperdícios do dia
      const wasteSnap = await db
        .collection("establishments")
        .doc(estId)
        .collection("waste")
        .get();

      let totalWasteKg = 0;
      let totalWasteCost = 0;
      wasteSnap.forEach((doc) => {
        const d = doc.data();
        totalWasteKg += d.wasteKg || 0;
        totalWasteCost += d.costReais || 0;
      });

      // Cálculo de economia evitada em relação à superprodução
      const preventedOverproduction = Math.max(0, expectedGuests - attendedGuests);
      const estimatedWasteAvoidedKg = preventedOverproduction * 0.08 * 0.85; // 80g média * 85% de assertividade
      const estimatedSavingsReais = estimatedWasteAvoidedKg * 14.5; // Custo médio ponderado por kg

      // Salva no histórico diário consolidado
      await db
        .collection("establishments")
        .doc(estId)
        .collection("history")
        .add({
          date: admin.firestore.FieldValue.serverTimestamp(),
          expectedGuests,
          attendedGuests,
          totalProductionKg: attendedGuests * 0.35,
          totalWasteKg,
          totalCost: (attendedGuests * 0.35 * 12.0) + totalWasteCost,
          wasteAvoidedKg: estimatedWasteAvoidedKg,
          savingsReais: estimatedSavingsReais,
        });

      console.log(`[SmartBuffet] Histórico consolidado para estabelecimento ${estId}`);
    }
  });
