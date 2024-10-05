<script>
    import { onMount, afterUpdate } from "svelte";
    import SelectedPages from "./SelectedPages.svelte";
    import PipelineConsole from "./PipelineConsole.svelte";
    import PipelineRunner from "./PipelineRunner.svelte";
    import AvailablePages from "./AvailablePages.svelte";

    let dropTargetElement;
    let consoleWrapper;
    let main;

    function adjustMainPadding() {
        if (consoleWrapper && main) {
            const consoleHeight = consoleWrapper.offsetHeight;
            main.style.paddingBottom = `${consoleHeight + 20}px`; // 20px extra for spacing
        }
    }

    function scrollConsoleToBottom() {
        if (consoleWrapper) {
            consoleWrapper.scrollTop = consoleWrapper.scrollHeight;
        }
    }

    onMount(() => {
        adjustMainPadding();
        // Set up a MutationObserver to watch for changes in the console content
        const observer = new MutationObserver(() => {
            adjustMainPadding();
            scrollConsoleToBottom();
        });
        observer.observe(consoleWrapper, { childList: true, subtree: true });
    });

    afterUpdate(() => {
        adjustMainPadding();
        scrollConsoleToBottom();
    });
</script>

<main bind:this={main}>
    <PipelineRunner />
    <div class="documents">
        <SelectedPages bind:dropTarget={dropTargetElement} />
        <AvailablePages dropTarget={dropTargetElement} />
    </div>
</main>
<div class="console-wrapper" bind:this={consoleWrapper}>
    <PipelineConsole />
</div>

<style>
    main {
        width: 90vw;
        max-width: 1000px;
        margin: 0 auto;
        padding: 20px;
    }
    .documents {
        display: flex;
        gap: 20px;
        max-width: 100%;
        overflow-x: hidden;
    }
    .console-wrapper {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        max-height: 10rem;
        overflow-y: auto;
        background-color: white;
        box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
        z-index: 1000;
    }
</style>
