<script>
    import { formattedStatuses } from "../store.js";
    import StatusRow from "./StatusRow.svelte";
</script>

<div class="status-display">
    {#each $formattedStatuses as status (status.key)}
        <StatusRow {...status} />
    {/each}
</div>

<style>
    .status-display {
        white-space: pre-wrap;
        word-wrap: break-word;
        max-height: 600px;
        overflow-y: auto;
        border: 1px solid #ccc;
        padding: 10px;
        font-family: monospace;
    }
</style>
