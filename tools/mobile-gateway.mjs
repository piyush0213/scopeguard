// One address for phones: serves the Flutter web app (Serverpod web server, :8082) and forwards app calls and
// live streams (Serverpod API, :8080) through the same origin, so a single tunnel URL works on any phone.
//   node tools/mobile-gateway.mjs            (listens on :8088)
import http from 'node:http';
import net from 'node:net';

const PORT = Number(process.env.GATEWAY_PORT || 8088);
const API = { host: '127.0.0.1', port: 8080 };
const WEB = { host: '127.0.0.1', port: 8082 };

// Serverpod RPC calls are POSTs; everything else (pages, assets) is the web app.
const targetFor = (req) => (req.method === 'POST' || req.method === 'OPTIONS' ? API : WEB);

const server = http.createServer((req, res) => {
  const t = targetFor(req);
  const up = http.request(
    { ...t, method: req.method, path: req.url, headers: { ...req.headers, host: `${t.host}:${t.port}` } },
    (r) => {
      res.writeHead(r.statusCode || 502, r.headers);
      r.pipe(res);
    },
  );
  up.on('error', () => {
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'text/plain' });
    res.end('ScopeGuard is starting up or not running. Run start-all.ps1 on the laptop.');
  });
  req.pipe(up);
});

// WebSockets (Serverpod streaming: live orders, Scope Room) go to the API server untouched.
server.on('upgrade', (req, socket, head) => {
  socket.setNoDelay(true);
  socket.setTimeout(0);
  // Drop proxy/compression headers: the tunnel and Serverpod each speak plain WebSocket frames.
  const headers = { ...req.headers, host: `${API.host}:${API.port}` };
  for (const h of Object.keys(headers)) {
    if (h.startsWith('cf-') || h.startsWith('x-forwarded') || h === 'sec-websocket-extensions' || h === 'cdn-loop') delete headers[h];
  }
  const up = http.request({ ...API, path: req.url, method: req.method, headers });
  up.on('upgrade', (res, upSocket, upHead) => {
    upSocket.setNoDelay(true);
    const lines = [`HTTP/1.1 101 ${res.statusMessage || 'Switching Protocols'}`];
    // Serverpod's 101 reply carries "content-length: 0". Cloudflare then treats the response body as finished
    // and never forwards server->phone WebSocket frames, so live streams time out. Drop body headers here.
    for (let i = 0; i < res.rawHeaders.length; i += 2) {
      if (/^(content-length|content-type|transfer-encoding)$/i.test(res.rawHeaders[i])) continue;
      lines.push(`${res.rawHeaders[i]}: ${res.rawHeaders[i + 1]}`);
    }
    socket.write(lines.join('\r\n') + '\r\n\r\n');
    if (upHead?.length) socket.write(upHead);
    if (head?.length) upSocket.write(head);
    if (process.env.GW_DEBUG) {
      const tag = Math.random().toString(36).slice(2, 6);
      console.log(tag, 'upgrade', req.url, JSON.stringify(req.headers));
      upSocket.on('data', (d) => console.log(tag, 'server->phone', d.length));
      socket.on('data', (d) => console.log(tag, 'phone->server', d.length));
    }
    upSocket.pipe(socket);
    socket.pipe(upSocket);
    const close = () => {
      socket.destroy();
      upSocket.destroy();
    };
    upSocket.on('error', close).on('close', close);
    socket.on('error', close).on('close', close);
  });
  up.on('response', (res) => {
    socket.end(`HTTP/1.1 ${res.statusCode} ${res.statusMessage}\r\n\r\n`);
  });
  up.on('error', () => socket.destroy());
  up.end();
});

server.listen(PORT, () => console.log(`mobile gateway on http://localhost:${PORT} -> app :${WEB.port}, api :${API.port}`));
