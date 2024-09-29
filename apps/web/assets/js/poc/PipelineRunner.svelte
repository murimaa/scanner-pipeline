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
            API_ENDPOINTS.STATUS_STREAM,
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
                handleScriptStarted(data);
                break;
            case "script_finished":
                handleScriptFinished(data);
                break;
            case "script_failed":
                handleScriptFailed(data);
                break;
            case "pipeline_failed":
                handlePipelineFailed(data);
                break;
            case "pipeline_finished":
                handlePipelineFinished(data);
                break;
        }
    }

    function handleScriptStarted(data) {
        $scriptStatuses = [
            ...$scriptStatuses.map((s) => ({ ...s, isCurrentStatus: false })),
            {
                ...data,
                status: "running",
                isCurrentStatus: true,
            },
        ];
    }

    function handleScriptFinished({ pipeline, script, execution_id }) {
        $scriptStatuses = $scriptStatuses.map((s) =>
            s.pipeline === pipeline &&
            s.script === script &&
            s.execution_id === execution_id
                ? { ...s, status: "finished", isCurrentStatus: false }
                : s,
        );
    }

    function handleScriptFailed({ pipeline, script, execution_id, reason }) {
        $scriptStatuses = $scriptStatuses.map((s) =>
            s.script === script && s.execution_id === execution_id
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
<StatusDisplay />
<PipelineStatus />
