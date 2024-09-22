<script>
    import { pipelineStatus } from "./store.js";

    function getStatusColor({ message }) {
        if (message.includes("failed")) return "red";
        if (message.includes("completed")) return "green";
        return "blue";
    }
</script>

<div class="pipeline-status">
    {#each $pipelineStatus as status}
        <div style="color: {getStatusColor(status)}">
            {status.message}
        </div>
    {/each}
</div>

<style>
    .pipeline-status {
        margin-bottom: 20px;
        font-family: monospace;
        font-size: 14px;
    }
</style>
