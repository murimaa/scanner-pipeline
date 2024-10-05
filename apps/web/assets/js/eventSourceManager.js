export function createEventSourceManager(
  url,
  onMessage,
  onOpen,
  onError,
  reconnectDelay,
) {
  let eventSource;
  let reconnectTimeout;

  function connect() {
    if (eventSource) {
      eventSource.close();
    }

    eventSource = new EventSource(url);

    eventSource.onopen = () => {
      if (reconnectTimeout) {
        clearTimeout(reconnectTimeout);
        reconnectTimeout = null;
      }
      onOpen();
    };

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      onMessage(data);
    };

    eventSource.onerror = (error) => {
      onError(error);
      eventSource.close();
      reconnectTimeout = setTimeout(connect, reconnectDelay);
    };
  }

  function disconnect() {
    if (eventSource) eventSource.close();
    if (reconnectTimeout) clearTimeout(reconnectTimeout);
  }

  return { connect, disconnect };
}
