import { writable, derived } from "svelte/store";

export const isRunning = writable(false);
export const pipelineStatus = writable([]);

// New store for script statuses
export const scriptStatuses = writable([]);

// Derived store for formatted and deduplicated status messages
export const formattedStatuses = derived(scriptStatuses, ($scriptStatuses) => {
  return Object.values(
    $scriptStatuses.reduce((acc, status) => {
      const key = `${status.executionId}-${status.script}`;
      acc[key] = {
        key: key,
        executionId: status.executionId,
        script: status.script,
        text: `${status.script}: ${status.status}`,
        status: status.status,
        isCurrentStatus: status.isCurrentStatus,
      };
      return acc;
    }, {}),
  );
});
