<script>
    import { onMount, onDestroy } from "svelte";
    import { isRunning, pipelineStatus } from "./store.js";
    import RunButton from "./RunButton.svelte";
    import { API_ENDPOINTS } from "./constants.js";

    function appendPipelineStatus(executionId, message) {
        $pipelineStatus = [...$pipelineStatus, { message }];
    }

    async function runPipeline() {
        $isRunning = true;
        appendPipelineStatus(null, "Starting pipeline...");

        try {
            await fetch(API_ENDPOINTS.RUN_PIPELINE, { method: "POST" });
        } catch (error) {
            appendPipelineStatus(null, `Error starting pipeline: ${error}`);
            $isRunning = false;
        }
    }
</script>

<RunButton on:click={runPipeline} />
