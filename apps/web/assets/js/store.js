import { writable } from "svelte/store";

export const currentStatus = writable(null);
export const statusMessages = writable([]);
export const isRunning = writable(false);
export const pipelineStatus = writable([]);
