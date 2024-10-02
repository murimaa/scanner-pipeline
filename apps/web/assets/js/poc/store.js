import { writable, derived } from "svelte/store";

export const isRunning = writable(false);
export const pipelineStatus = writable([]);

// New store for script statuses
export const scriptStatuses = writable([]);

// Derived store for formatted and deduplicated status messages
export const formattedStatuses = derived(scriptStatuses, ($scriptStatuses) => {
  return Object.values(
    $scriptStatuses.reduce((acc, status) => {
      const key = `${status.execution_id}-${status.pipeline}-${status.script}`;
      acc[key] = {
        ...status,
        key: key,
        text: `${status.script}: ${status.status}`,
      };
      return acc;
    }, {}),
  );
});

export const thumbnails = writable([]);
export const documents = writable([]);
