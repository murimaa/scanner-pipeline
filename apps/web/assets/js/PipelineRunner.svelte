<script>
  import { onMount } from 'svelte';
  import { currentStatus, statusMessages, isRunning } from './store.js';
  import RunButton from './RunButton.svelte';
  import StatusDisplay from './StatusDisplay.svelte';

  const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
  let currentSpinnerIndex = 0;
  let spinnerInterval;

  onMount(() => {
    connectToEventStream();
    return () => {
      if (spinnerInterval) clearInterval(spinnerInterval);
    };
  });

  function connectToEventStream() {
    appendStatus('Connecting to status stream...');

    const eventSource = new EventSource('/api/pipeline/stream_status');

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      handleStatusUpdate(data);
    };

    eventSource.onerror = (error) => {
      appendStatus('Error in status stream: ' + error, 'red');
      appendStatus('Closing stream. Please refresh.', 'red');
      eventSource.close();
      stopSpinner();
    };
  }

  function handleStatusUpdate(data) {
    switch(data.event) {
      case 'script_started':
        if ($currentStatus && $currentStatus.status === 'started') {
          updateStatus('✓', 'green');
        }
        $currentStatus = { script: data.script, status: 'started' };
        appendStatus(formatStatus(spinnerFrames[currentSpinnerIndex]), 'blue', true);
        startSpinner();
        break;
      case 'script_finished':
        stopSpinner();
        $currentStatus.status = 'finished';
        updateStatus('✓', 'green');
        $currentStatus = null;
        break;
      case 'script_failed':
        stopSpinner();
        $currentStatus.status = 'failed';
        updateStatus('✗', 'red');
        appendStatus(`Script failed: ${data.script}`, 'red');
        appendStatus(`Reason: ${data.reason}`, 'red');
        $currentStatus = null;
        break;
      case 'pipeline_failed':
        appendStatus(`Pipeline failed: ${data.reason}`, 'red');
        stopSpinner();
        $isRunning = false;
        break;
      case 'pipeline_finished':
        appendStatus('Pipeline completed successfully.', 'green');
        stopSpinner();
        $isRunning = false;
        break;
    }
  }

  function startSpinner() {
    if (!spinnerInterval) {
      spinnerInterval = setInterval(() => {
        currentSpinnerIndex = (currentSpinnerIndex + 1) % spinnerFrames.length;
        updateStatus(spinnerFrames[currentSpinnerIndex], 'blue');
      }, 100);
    }
  }

  function stopSpinner() {
    if (spinnerInterval) {
      clearInterval(spinnerInterval);
      spinnerInterval = null;
    }
  }

  function formatStatus(prefix) {
    if ($currentStatus) {
      return `${prefix} ${$currentStatus.script}: ${$currentStatus.status}`;
    }
    return '';
  }

  function updateStatus(prefix, color) {
    $statusMessages = $statusMessages.map((msg, index) =>
      index === $statusMessages.length - 1 && msg.isCurrentStatus
        ? { ...msg, message: formatStatus(prefix), color }
        : msg
    );
  }

  function appendStatus(message, color = 'black', isCurrentStatus = false) {
    $statusMessages = [...$statusMessages, { message, color, isCurrentStatus }];
  }

  async function runPipeline() {
    $isRunning = true;
    appendStatus('Starting pipeline...');

    try {
      await fetch('/api/pipeline/run', { method: 'POST' });
    } catch (error) {
      appendStatus('Error starting pipeline: ' + error, 'red');
      $isRunning = false;
    }
  }
</script>

<RunButton on:click={runPipeline} />
<StatusDisplay />
