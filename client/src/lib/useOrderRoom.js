import { useCallback, useEffect, useState } from 'react';
import { api } from './api.js';
import { getSocket } from './socket.js';

/** Loads an order + chat, joins its Socket.IO room and keeps everything live. */
export function useOrderRoom(orderId) {
  const [order, setOrder] = useState(null);
  const [messages, setMessages] = useState([]);
  const [git, setGit] = useState(null);
  const [error, setError] = useState('');
  const [typing, setTyping] = useState(null);
  const [checking, setChecking] = useState({});
  const [connected, setConnected] = useState(false);
  const [flashKey, setFlashKey] = useState(0);

  const reload = useCallback(async () => {
    try {
      const d = await api(`/api/orders/${orderId}`);
      setOrder(d.order);
      setMessages(d.messages);
      if (d.git) setGit(d.git);
      setError('');
    } catch (e) {
      setError(e.message);
    }
  }, [orderId]);

  useEffect(() => {
    reload();
    const s = getSocket();
    if (!s) return;
    let wasDisconnected = false;
    const join = () => {
      setConnected(true);
      s.emit('order:join', { orderId });
      if (wasDisconnected) reload(); // catch anything missed while disconnected
    };
    const onDisconnect = () => {
      wasDisconnected = true;
      setConnected(false);
    };
    const onOrder = (o) => {
      if (o.id !== orderId) return;
      setOrder((prev) => {
        if (prev && prev.quote?.version !== o.quote?.version) setFlashKey((k) => k + 1);
        return o;
      });
    };
    const onMsg = (m) => {
      if (m.orderId !== orderId) return;
      setMessages((list) => (list.some((x) => x.id === m.id) ? list : [...list, m]));
      setTyping(null);
    };
    const onUpdated = ({ id, metadata }) =>
      setMessages((list) => list.map((m) => (m.id === id ? { ...m, metadata: { ...m.metadata, ...metadata } } : m)));
    const onFlag = (f) => {
      setChecking((c) => ({ ...c, [f.messageId]: false }));
      setMessages((list) =>
        list.map((m) =>
          m.id === f.messageId ? { ...m, scopeFlagged: f.outOfScope, metadata: { ...m.metadata, scopeCheck: f } } : m,
        ),
      );
    };
    const onChecking = ({ messageId }) => setChecking((c) => ({ ...c, [messageId]: true }));
    let typingTimer;
    const onTyping = (t) => {
      if (t.orderId !== orderId) return;
      setTyping(t);
      clearTimeout(typingTimer);
      typingTimer = setTimeout(() => setTyping(null), 2500);
    };

    if (s.connected) join();
    s.on('connect', join);
    s.on('disconnect', onDisconnect);
    s.on('order:updated', onOrder);
    s.on('chat:message', onMsg);
    s.on('chat:updated', onUpdated);
    s.on('scope:flagged', onFlag);
    s.on('scope:checking', onChecking);
    s.on('chat:typing', onTyping);
    return () => {
      s.emit('order:leave', { orderId });
      s.off('connect', join);
      s.off('disconnect', onDisconnect);
      s.off('order:updated', onOrder);
      s.off('chat:message', onMsg);
      s.off('chat:updated', onUpdated);
      s.off('scope:flagged', onFlag);
      s.off('scope:checking', onChecking);
      s.off('chat:typing', onTyping);
      clearTimeout(typingTimer);
    };
  }, [orderId, reload]);

  const send = useCallback(
    (content) =>
      new Promise((resolve, reject) => {
        const s = getSocket();
        const viaRest = () =>
          api(`/api/orders/${orderId}/messages`, { method: 'POST', body: { content } })
            .then((d) => {
              setMessages((list) => (list.some((x) => x.id === d.message.id) ? list : [...list, d.message]));
              resolve(d.message);
            })
            .catch(reject);
        if (!s?.connected) return viaRest();
        s.timeout(8000).emit('chat:send', { orderId, content }, (err, res) => {
          if (err) return viaRest();
          if (!res.ok) return reject(new Error(res.error));
          resolve(res.message);
        });
      }),
    [orderId],
  );

  const typingPing = useCallback(() => getSocket()?.emit('chat:typing', { orderId }), [orderId]);

  return { order, setOrder, messages, git, error, reload, send, typing, typingPing, checking, connected, flashKey };
}
