<script>
    import { onMount, onDestroy, tick } from "svelte";
    import { documents } from "./store.js";
    import { writable, derived } from "svelte/store";
    import DropTarget from "./DropTarget.svelte";
    import { TRANSITION_DURATION } from "./constants.js";
    export let dropTarget;
    let selectedPages = [];
    let thumbnails = [];

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
        const newDocuments = $documents.filter((d) => d !== document);
        selectedPages = thumbnails.filter((t) =>
            newDocuments
                .flat()
                .map((p) => p.name)
                .includes(t.name),
        );
        $documents = newDocuments;
    }
</script>

<div class="container">
    {#each $delayedDocuments as document}
        {#if document.length > 0}
            <div class="document-cover">
                <img src={document[0].url} alt={document[0].name} />
                <button
                    class="unselect-btn"
                    on:click={() => unselectDocument(document)}
                >
                    Unselect
                </button>
                <p>{document[0].name}</p>
            </div>
        {/if}
    {/each}
    <DropTarget bind:node={dropTarget} />
</div>

<style>
    .container {
    }
    .document-cover {
        position: relative;
    }
    .unselect-btn {
        position: absolute;
        left: 5px;
        background-color: rgba(255, 0, 0, 0.7);
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
