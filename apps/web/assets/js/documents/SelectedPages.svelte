<script>
    import { onMount, onDestroy, tick } from "svelte";
    import { documents, thumbnails } from "../store.js";
    import { TRANSITION_DURATION } from "../constants.js";
    import { writable, derived } from "svelte/store";
    import DropTarget from "./DropTarget.svelte";

    export let dropTarget;

    // Create a local delayed store
    function createDelayedStore(store, delay) {
        const delayed = writable([]);

        const unsubscribe = store.subscribe((value) => {
            setTimeout(() => {
                delayed.set(value);
            }, delay);
        });

        onDestroy(unsubscribe);

        return delayed;
    }

    // Create the delayed documents store
    const delayedDocuments = createDelayedStore(documents, TRANSITION_DURATION);

    function unselectDocument(document) {
        // comparing the name of the first page should be enough
        $documents = $documents.filter((d) => d[0].name !== document[0].name);
    }

    // Filtered and delayed documents
    $: filteredDelayedDocuments = $delayedDocuments
        .map((document) =>
            document.filter((page) =>
                $thumbnails.some((t) => t.name === page.name),
            ),
        )
        .filter((document) => document.length > 0);
</script>

<div class="container">
    {#each filteredDelayedDocuments as document}
        {#if document.length > 0}
            <div class="document-cover">
                <img src={document[0].url} alt={document[0].name} />
                <div class="metadata">
                    {document.length}
                    {document.length == 1 ? "page" : "pages"}
                </div>
                <button
                    class="unselect-btn"
                    on:click={() => unselectDocument(document)}
                >
                    Unselect
                </button>
            </div>
        {/if}
    {/each}
    <DropTarget bind:node={dropTarget} />
</div>

<style>
    .document-cover {
        position: relative;
    }
    .metadata {
        position: absolute;
        right: 5px;
        top: 5px;
        background-color: rgba(255, 255, 255, 0.9);
        border-radius: 5px;
        padding: 5px 10px;
    }
    .unselect-btn {
        position: absolute;
        left: 5px;
        background-color: rgba(255, 0, 0, 0.85);
        color: white;
        top: 5px;
        border: none;
        border-radius: 5px;
        padding: 5px 10px;
        font-size: 14px;
        cursor: pointer;
    }
    .unselect-btn:hover {
        background-color: rgba(200, 0, 0, 0.7);
    }
</style>
