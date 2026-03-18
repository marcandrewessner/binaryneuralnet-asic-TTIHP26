# This function is used to plot and save the
# results of a compressed network

import torch
from matplotlib import pyplot as plt


# The layout contains rows:
#   row 0 — original images   (n_samples columns)
#   row 1 — compressed images (n_samples columns)

def plot_preprocessed_image_table(
    model,
    model_name,
    dataset_loader: torch.utils.data.DataLoader,
    n_samples: int = 10,
):
    pltimg = lambda x: x.squeeze().detach().cpu().numpy()

    # Collect samples (image tensor + integer label)
    samples = [dataset_loader.dataset[i] for i in range(n_samples)]
    images = [s[0] for s in samples]
    labels = [s[1] for s in samples]

    fig, axes = plt.subplots(2, n_samples, figsize=(2 * n_samples, 5))
    fig.suptitle(
        f"{model_name}\nOriginal vs Preprocessed input",
        fontsize=13,
        fontweight="bold",
    )

    # Row labels on the leftmost column
    axes[0, 0].set_ylabel("Original", fontsize=10, fontweight="bold")
    axes[1, 0].set_ylabel("Preprocessed", fontsize=10, fontweight="bold")

    model.eval()
    with torch.no_grad():
        for i, (img, label) in enumerate(zip(images, labels)):
            # ── original ────────────────────────────────────────────────
            orig_np = pltimg(img)
            h_o, w_o = orig_np.shape
            axes[0, i].imshow(orig_np, cmap="gray", vmin=0, vmax=1)
            axes[0, i].set_title(f"digit: {label}", fontsize=8)
            axes[0, i].set_xlabel(f"{h_o}×{w_o} px", fontsize=7)
            axes[0, i].set_xticks([])
            axes[0, i].set_yticks([])

            # ── compressed ──────────────────────────────────────────────
            compressed = model(img.unsqueeze(0))  # (1,1,H,W)
            comp_np = pltimg(compressed)
            h_c, w_c = comp_np.shape
            ratio = (h_c * w_c) / (h_o * w_o)
            axes[1, i].imshow(comp_np, cmap="gray", vmin=0, vmax=1)
            axes[1, i].set_title(f"digit: {label}", fontsize=8)
            axes[1, i].set_xlabel(
                f"{h_c}×{w_c} px  ({ratio:.0%})", fontsize=7
            )
            axes[1, i].set_xticks([])
            axes[1, i].set_yticks([])

    plt.tight_layout()

    save_path = f"data/model_reports/{model_name}_preprocessed.png"
    fig.savefig(save_path, dpi=150, bbox_inches="tight")
    print(f"Saved: {save_path}")
