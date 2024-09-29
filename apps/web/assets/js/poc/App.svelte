<script>
    import PipelineConsole from "./PipelineConsole.svelte";
    import PipelineRunner from "./PipelineRunner.svelte";
    import ThumbnailDisplay from "./ThumbnailDisplay.svelte";
</script>

<main>
    <PipelineRunner />
    <h1>Generated Thumbnails</h1>
    <ThumbnailDisplay />
    <h2>Pipeline Runner</h2>
    <PipelineConsole />
</main>

<style>
    main {
        max-width: 800px;
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
