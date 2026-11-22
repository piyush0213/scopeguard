import { io } from 'socket.io-client';
import { getToken } from './api.js';

let socket = null;
let socketToken = null;

/** One authenticated socket per JWT; reconnects automatically. */
export function getSocket() {
  const token = getToken();
  if (!token) return null;
  if (socket && socketToken === token) return socket;
  socket?.disconnect();
  socketToken = token;
  socket = io({ auth: { token }, transports: ['websocket', 'polling'] });
  return socket;
}

export function closeSocket() {
  socket?.disconnect();
  socket = null;
  socketToken = null;
}
