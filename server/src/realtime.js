import { Server } from 'socket.io';
import { verifyToken } from './auth.js';

let io = null;

export const emit = {
  toOrder: (orderId, event, data) => io?.to(`order:${orderId}`).emit(event, data),
  toOrderDevs: (orderId, event, data) => io?.to(`order:${orderId}:dev`).emit(event, data),
  toDevs: (event, data) => io?.to('devs').emit(event, data),
  toUser: (userId, event, data) => io?.to(`user:${userId}`).emit(event, data),
  // Socket.IO de-duplicates across rooms, so a socket in several of them gets the event once.
  toRooms: (rooms, event, data) => io?.to(rooms).emit(event, data),
};

/** handlers: { canJoin(user, orderId) -> Promise<bool>, onChat(user, orderId, text) -> Promise } */
export function initRealtime(httpServer, corsOrigin, handlers) {
  io = new Server(httpServer, { cors: { origin: corsOrigin, credentials: true } });

  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      const p = verifyToken(token);
      socket.data.user = { id: p.userId, role: p.role, name: p.name };
      next();
    } catch {
      next(new Error('unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const user = socket.data.user;
    socket.join(`user:${user.id}`);
    if (user.role === 'dev') socket.join('devs');

    socket.on('order:join', async ({ orderId } = {}, ack) => {
      try {
        if (!(await handlers.canJoin(user, orderId))) throw new Error('forbidden');
        socket.join(`order:${orderId}`);
        if (user.role === 'dev') socket.join(`order:${orderId}:dev`);
        ack?.({ ok: true });
      } catch (e) {
        ack?.({ ok: false, error: e.message });
      }
    });

    socket.on('order:leave', ({ orderId } = {}) => {
      socket.leave(`order:${orderId}`);
      socket.leave(`order:${orderId}:dev`);
    });

    socket.on('chat:send', async ({ orderId, content } = {}, ack) => {
      try {
        const msg = await handlers.onChat(user, orderId, content);
        ack?.({ ok: true, message: msg });
      } catch (e) {
        ack?.({ ok: false, error: e.message });
      }
    });

    socket.on('chat:typing', ({ orderId } = {}) => {
      if (socket.rooms.has(`order:${orderId}`)) {
        socket.to(`order:${orderId}`).emit('chat:typing', { orderId, name: user.name, role: user.role });
      }
    });
  });

  return io;
}
