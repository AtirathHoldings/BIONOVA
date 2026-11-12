import { Client } from '@stomp/stompjs';

let stompClient = null;
let isConnected = false;

/**
 * Initializes and connects the STOMP WebSocket client over native browser WebSocket.
 * Subscribes to:
 *   - /topic/notifications  (real-time in-app alerts)
 *   - /topic/tasks          (live status / task assignments)
 *   - /topic/dashboard-refresh (triggers background dashboard reload)
 */
export function connectWebSocket({
  onNotification = null,
  onTaskUpdate = null,
  onDashboardRefresh = null,
} = {}) {
  // If already active and connected, return existing client
  if (stompClient && isConnected) {
    return stompClient;
  }

  const rawBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';
  // Convert http(s) URL to ws(s) broker URL
  const brokerURL = rawBaseUrl.replace(/^http/i, 'ws').replace(/\/$/, '') + '/ws';

  stompClient = new Client({
    brokerURL: brokerURL,
    reconnectDelay: 5000,
    heartbeatIncoming: 10000,
    heartbeatOutgoing: 10000,
    debug: () => {
      // Kept clean in production
    },
    onConnect: () => {
      isConnected = true;
      console.log('⚡ [BioNova WebSocket] Connected to real-time broker at', brokerURL);

      // 1. Subscribe to Notifications
      stompClient.subscribe('/topic/notifications', (message) => {
        try {
          const payload = JSON.parse(message.body);
          if (onNotification) onNotification(payload);
          window.dispatchEvent(new CustomEvent('bionova:notification', { detail: payload }));
        } catch (e) {
          console.error('Error parsing notification message', e);
        }
      });

      // 2. Subscribe to Task updates
      stompClient.subscribe('/topic/tasks', (message) => {
        try {
          const payload = JSON.parse(message.body);
          if (onTaskUpdate) onTaskUpdate(payload);
          window.dispatchEvent(new CustomEvent('bionova:task_update', { detail: payload }));
          window.dispatchEvent(new CustomEvent('bionova:refresh', { detail: payload }));
        } catch (e) {
          console.error('Error parsing task message', e);
        }
      });

      // 3. Subscribe to Dashboard refresh events
      stompClient.subscribe('/topic/dashboard-refresh', (message) => {
        try {
          const payload = JSON.parse(message.body);
          if (onDashboardRefresh) onDashboardRefresh(payload);
          window.dispatchEvent(new CustomEvent('bionova:refresh', { detail: payload }));
        } catch (e) {
          console.error('Error parsing dashboard refresh message', e);
        }
      });
    },
    onDisconnect: () => {
      isConnected = false;
      console.log('🔌 [BioNova WebSocket] Disconnected');
    },
    onStompError: (frame) => {
      console.warn('⚠️ [BioNova WebSocket] STOMP Error:', frame.headers['message']);
    },
    onWebSocketClose: () => {
      isConnected = false;
    },
  });

  stompClient.activate();
  return stompClient;
}

/**
 * Disconnects the STOMP WebSocket client cleanly.
 */
export function disconnectWebSocket() {
  if (stompClient) {
    try {
      stompClient.deactivate();
    } catch (e) {
      // Ignore
    }
    stompClient = null;
    isConnected = false;
  }
}
