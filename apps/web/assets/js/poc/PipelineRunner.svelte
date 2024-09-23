<script>
    import { onMount, onDestroy } from "svelte";
    import { isRunning, pipelineStatus, scriptStatuses } from "./store.js";
    import RunButton from "./RunButton.svelte";
    import StatusDisplay from "./StatusDisplay.svelte";
    import PipelineStatus from "./PipelineStatus.svelte";
    import { createEventSourceManager } from "./eventSourceManager.js";
    import { RECONNECT_DELAY, API_ENDPOINTS } from "./constants.js";

    let eventSourceManager;

    onMount(() => {
        eventSourceManager = createEventSourceManager(
            API_ENDPOINTS.STREAM_STATUS,
            handleStatusUpdate,
            handleEventSourceOpen,
            handleEventSourceError,
            RECONNECT_DELAY,
        );
        eventSourceManager.connect();

        return () => {
            eventSourceManager.disconnect();
        };
    });

    function handleEventSourceOpen() {
        appendPipelineStatus(null, "Connected to status stream");
    }

    function handleEventSourceError(error) {
        appendPipelineStatus(
            null,
            `Error in status stream: ${error}. Attempting to reconnect...`,
        );
    }

    function handleStatusUpdate(data) {
        switch (data.event) {
            case "script_started":
                handleScriptStarted(data.execution_id, data.script);
                break;
            case "script_finished":
                handleScriptFinished(data.execution_id, data.script);
                break;
            case "script_failed":
                handleScriptFailed(data.execution_id, data.script, data.reason);
                break;
            case "pipeline_failed":
                handlePipelineFailed(data.execution_id, data.reason);
                break;
            case "pipeline_finished":
                handlePipelineFinished(data.execution_id);
                break;
        }
    }

    function handleScriptStarted(executionId, script) {
        console.log("started", script);

        $scriptStatuses = [
            ...$scriptStatuses.map((s) => ({ ...s, isCurrentStatus: false })),
            {
                executionId: executionId,
                script,
                status: "running",
                isCurrentStatus: true,
            },
        ];
    }

    function handleScriptFinished(executionId, script) {
        console.log("finished", script);
        $scriptStatuses = $scriptStatuses.map((s) =>
            s.script === script && s.executionId === executionId
                ? { ...s, status: "finished", isCurrentStatus: false }
                : s,
        );
    }

    function handleScriptFailed(executionId, script, reason) {
        $scriptStatuses = $scriptStatuses.map((s) =>
            s.script === script && s.executionId === executionId
                ? { ...s, status: "failed", reason, isCurrentStatus: false }
                : s,
        );
    }

    function handlePipelineFailed(executionId, reason) {
        appendPipelineStatus(null, `Pipeline failed: ${reason}`);
        $isRunning = false;
    }

    function handlePipelineFinished(executionId) {
        appendPipelineStatus(null, "Pipeline completed successfully.");
        $isRunning = false;
    }

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
<PipelineStatus />
<StatusDisplay />
