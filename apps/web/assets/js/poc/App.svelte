<script>
    import PipelineConsole from "./PipelineConsole.svelte";
    import PipelineRunner from "./PipelineRunner.svelte";
    import ThumbnailDisplay from "./ThumbnailDisplay.svelte";
</script>

<main>
    <PipelineRunner />
    <ThumbnailDisplay />
    <h2>Pipeline Runner</h2>
    <PipelineConsole />
</main>

<style>
    main {
        width: 90vw;
        max-width: 1000px;
        margin: 0 auto;
        padding: 20px;
    }

    h1,
    h2 {
        text-align: center;
        color: #333;
        margin-bottom: 20px;
    }
</style>
