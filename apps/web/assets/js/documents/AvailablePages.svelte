<script>
    import { onMount, onDestroy } from "svelte";
    import { derived } from "svelte/store";

    import { documents, thumbnails } from "../store.js";
    import { createEventSourceManager } from "../eventSourceManager.js";
    import {
        TRANSITION_DURATION,
        RECONNECT_DELAY,
        API_ENDPOINTS,
    } from "../constants.js";
    import { fly, fade } from "svelte/transition";
    export let dropTarget;

    let eventSourceManager;
    onMount(() => {
        eventSourceManager = createEventSourceManager(
            API_ENDPOINTS.THUMBNAIL_STREAM,
            handleThumbnailUpdate,
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
        console.log("Connected to thumbnail stream");
    }

    function handleEventSourceError(error) {
        console.error(
            `Error in thumbnail stream: ${error}. Attempting to reconnect...`,
        );
    }

    function handleThumbnailUpdate(data) {
        if (data.event === "thumbnails") {
            const newThumbnails = data.data;
            $thumbnails = newThumbnails;

            // Update $documents to remove pages that no longer exist in thumbnails
            $documents = $documents
                .map((document) =>
                    document.filter((page) =>
                        newThumbnails.some((t) => t.name === page.name),
                    ),
                )
                .filter((document) => document.length > 0);
        }
    }

    function stripExtension(filename) {
        return filename.substring(0, filename.lastIndexOf(".")) || filename;
    }

    async function deleteThumbnail(filename) {
        try {
            const response = await fetch(
                `${API_ENDPOINTS.DELETE_PAGE}?page=${filename}`,
                {
                    method: "DELETE",
                },
            );
            if (response.ok) {
                // Remove from selectedPages if it was selected
                $thumbnails = $thumbnails.filter((p) => p.name !== filename);
            } else {
                console.error("Failed to delete thumbnail");
            }
        } catch (error) {
            console.error("Error deleting thumbnail:", error);
        }
    }

    function selectPage(thumbnail) {
        // Select all pages up until the one clicked
        const index = $thumbnails.findIndex((t) => t.name === thumbnail.name);
        if (index !== -1) {
            const pagesToAdd = $thumbnails
                .slice(0, index + 1)
                .filter(
                    (t) =>
                        !$derivedPages.selectedPages.some(
                            (s) => s.name === t.name,
                        ),
                );
            $documents = [...$documents, pagesToAdd];
        }
    }

    const derivedPages = derived(
        [documents, thumbnails],
        ([$documents, $thumbnails]) => {
            const selectedPages = $thumbnails.filter((t) =>
                $documents
                    .flat()
                    .map((p) => p.name)
                    .includes(t.name),
            );
            const remainingThumbnails = $thumbnails.filter(
                (t) => !selectedPages.some((s) => s.name === t.name),
            );
            return { selectedPages, remainingThumbnails };
        },
    );

    function flyAndScale(node, { delay = 0, duration = 400, target } = {}) {
        const style = getComputedStyle(node);
        const getCoords = (elem) => ({
            x: elem.getBoundingClientRect().left,
            y: elem.getBoundingClientRect().top,
        });
        const dx = getCoords(target).x - getCoords(node).x;
        const dy = getCoords(target).y - getCoords(node).y;
        const scale = target.offsetWidth / node.offsetWidth;
        const transform = style.transform === "none" ? "" : style.transform;
        return {
            delay,
            duration,
            css: (t, u) => {
                const current_scale_percentage = 1 - u * (1 - scale);
                const scale_compensated_x =
                    -0.5 * node.offsetWidth * (1 - current_scale_percentage);
                const scale_compensated_y =
                    -0.5 * node.offsetHeight * (1 - current_scale_percentage);
                const translateX = scale_compensated_x + (1 - t) * dx;
                const translateY = scale_compensated_y + (1 - t) * dy;
                const css = `
			    transform: ${transform} translate(${translateX}px, ${translateY}px) scale(${current_scale_percentage});
                `;
                return css;
            },
        };
    }
</script>

<div class="main-container">
    <div class="thumbnail-container">
        {#each $derivedPages.remainingThumbnails as thumbnail (thumbnail.name)}
            <div
                class="thumbnail"
                out:flyAndScale={{
                    target: dropTarget,
                    duration: TRANSITION_DURATION,
                    delay: 0,
                }}
            >
                <img src={thumbnail.url} alt={thumbnail.name} />
                <button
                    class="delete-btn"
                    on:click={() => deleteThumbnail(thumbnail.name)}
                >
                    🗑️
                </button>
                <div class="cut">
                    <button
                        class="select-btn"
                        on:click={() => selectPage(thumbnail)}
                    >
                        Cut
                    </button>
                </div>
            </div>
        {/each}
    </div>
</div>

<style>
    .thumbnail-container {
        display: flex;
        flex-direction: column;
        gap: 10px;
        padding: 10px;
    }

    .thumbnail {
        position: relative;
        width: 100%;
        text-align: center;
    }

    .thumbnail img,
    .delete-btn,
    .select-btn {
        background-color: rgba(255, 255, 255, 0.7);
        border: none;
        border-radius: 5px;
        padding: 5px 10px;
        font-size: 14px;
        cursor: pointer;
    }

    .delete-btn {
        position: absolute;
        top: 5px;
        right: 5px;
    }

    .cut {
        position: relative;
        padding: 5px 0;
    }

    .cut::before {
        content: "";
        position: absolute;
        top: 50%;
        left: 0;
        right: 0;
        border-top: 1px dashed darkgray;
        z-index: 1;
    }

    .cut button {
        background-color: rgba(0, 255, 0, 0.7);
        position: relative; /* Add this line */
        z-index: 2; /* Ensure the button is above the line */
    }

    .delete-btn:hover {
        background-color: rgba(255, 0, 0, 0.7);
        color: white;
    }

    .select-btn:hover {
        background-color: rgba(0, 200, 0, 0.7);
    }
</style>
