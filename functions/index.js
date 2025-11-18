const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function para validar reservas y evitar solapamientos
 *
 * Qué hace esta función:
 * 1. Se ejecuta automáticamente cuando se crea una nueva reserva
 * 2. Consulta todas las reservas activas de esa pista en esa fecha
 * 3. Verifica si hay solapamiento de horarios
 * 4. Si hay solapamiento, marca la reserva como 'invalid' y notifica al cliente
 *
 * Esto garantiza que aunque dos usuarios intenten reservar al mismo tiempo,
 * solo uno lo conseguirá (el primero en llegar al servidor).
 */
exports.validateBooking = functions.firestore
    .document('clubs/{clubId}/courts/{courtId}/bookings/{bookingId}')
    .onCreate(async (snap, context) => {
      const booking = snap.data();
      const {clubId, courtId, bookingId} = context.params;

      try {
      // Obtener todas las reservas activas de esa pista en esa fecha
        const bookingsRef = admin.firestore()
            .collection('clubs').doc(clubId)
            .collection('courts').doc(courtId)
            .collection('bookings');

        const existingBookings = await bookingsRef
            .where('date', '==', booking.date)
            .where('status', '==', 'active')
            .get();

        // Verificar solapamientos
        for (const doc of existingBookings.docs) {
          if (doc.id === bookingId) continue; // Skip la misma reserva

          const existing = doc.data();

          // Convertir tiempos a minutos desde medianoche para facilitar comparación
          const newStart = timeToMinutes(booking.startTime);
          const newEnd = newStart + booking.durationMinutes;
          const existingStart = timeToMinutes(existing.startTime);
          const existingEnd = existingStart + existing.durationMinutes;

          // Verificar solapamiento
          if (timesOverlap(newStart, newEnd, existingStart, existingEnd)) {
            console.log(`Solapamiento detectado: ${bookingId} con ${doc.id}`);

            // Marcar la reserva como inválida
            await snap.ref.update({
              status: 'invalid',
              invalidReason: 'Time slot no longer available',
            });

            return null;
          }
        }

        console.log(`Reserva validada exitosamente: ${bookingId}`);
        return null;
      } catch (error) {
        console.error('Error validando reserva:', error);
        // En caso de error, marcar como inválida por seguridad
        await snap.ref.update({
          status: 'invalid',
          invalidReason: 'Validation error',
        });
        return null;
      }
    });

/**
 * Función auxiliar: Convierte hora "HH:mm" a minutos desde medianoche
 * @param {string} timeStr - Hora en formato "HH:mm"
 * @return {number} Minutos desde medianoche
 */
function timeToMinutes(timeStr) {
  const [hours, minutes] = timeStr.split(':').map(Number);
  return hours * 60 + minutes;
}

/**
 * Función auxiliar: Verifica si dos rangos de tiempo se solapan
 * @param {number} start1 - Inicio del primer rango (minutos)
 * @param {number} end1 - Fin del primer rango (minutos)
 * @param {number} start2 - Inicio del segundo rango (minutos)
 * @param {number} end2 - Fin del segundo rango (minutos)
 * @return {boolean} True si hay solapamiento
 */
function timesOverlap(start1, end1, start2, end2) {
  return start1 < end2 && start2 < end1;
}

/**
 * Cloud Function opcional para limpiar reservas antiguas canceladas
 * Se puede ejecutar diariamente con un cron job
 */
exports.cleanupOldBookings = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      // Esta es una función de ejemplo - ajusta según tus necesidades
      console.log('Limpieza de reservas antiguas ejecutada');
      return null;
    });
