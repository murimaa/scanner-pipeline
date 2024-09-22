<script>
    import { statusMessages } from "./store.js";

    $: sortedMessages = $statusMessages.sort((a, b) =>
        a.isCurrentStatus ? 1 : b.isCurrentStatus ? -1 : 0,
    );

    function getStatusSymbol(status) {
        switch (status) {
            case "finished":
                return "✓";
            case "failed":
                return "✗";
            default:
                return "⏳";
        }
    }
</script>

<div class="status-display">
    {#each sortedMessages as { message, color, isCurrentStatus, status }}
        <div class:current-status={isCurrentStatus}>
            <span style="color: {color}">
                {#if status}{getStatusSymbol(status)}{/if}
                {message}
            </span>
        </div>
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
    .current-status {
        font-weight: bold;
    }
    div {
        margin: 0;
        padding: 0;
    }
</style>
