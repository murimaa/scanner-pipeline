import { writable, derived } from "svelte/store";

export const isRunning = writable(false);
export const pipelineStatus = writable([]);

// New store for script statuses
export const scriptStatuses = writable([]);

// Derived store for formatted status messages
export const formattedStatuses = derived(scriptStatuses, ($scriptStatuses) =>
  $scriptStatuses.map((status) => ({
    id: status.id,
    text: `${status.script}: ${status.status}`,
    status: status.status,
    isCurrentStatus: status.isCurrentStatus,
  })),
);
