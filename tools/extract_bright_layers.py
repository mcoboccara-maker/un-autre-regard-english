"""
Extract bright/luminous elements from menu card images.
Creates transparent PNG overlays that can be animated independently.
"""
import os
from PIL import Image, ImageFilter
import numpy as np

ASSETS = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'assets')

# Configuration per image: (input, output, luminosity_threshold, blur_radius)
IMAGES = [
    {
        'input': 'exprime_ce_qui_te_traverse.png',
        'output': 'exprime_glow_layer.png',
        'threshold': 140,  # Brain energy is very bright golden
        'blur': 2,
        'description': 'Brain energy glow',
    },
    {
        'input': 'partage_ce_que_tu_ressens.png',
        'output': 'partage_glow_layer.png',
        'threshold': 150,  # Heart glow is very bright
        'blur': 2,
        'description': 'Heart glow',
    },
    {
        'input': 'mon_chemin_parcouru.png',
        'output': 'chemin_glow_layer.png',
        'threshold': 130,  # Luminous river path
        'blur': 1,
        'description': 'Luminous river',
    },
    {
        'input': 'connecte toi aux sources.png',
        'output': 'sources_glow_layer.png',
        'threshold': 100,  # Stars/cosmos are bright but on dark bg
        'blur': 1,
        'description': 'Cosmic stars',
    },
]


def extract_bright_layer(input_path, output_path, threshold, blur_radius):
    """
    Extract bright elements from an image into a transparent layer.

    Strategy:
    - Calculate per-pixel luminosity
    - Pixels above threshold: keep with alpha proportional to brightness
    - Pixels below threshold: make transparent
    - Apply slight blur to smooth edges
    """
    img = Image.open(input_path).convert('RGBA')
    pixels = np.array(img, dtype=np.float32)

    # Calculate luminosity (perceived brightness)
    r, g, b, a = pixels[:,:,0], pixels[:,:,1], pixels[:,:,2], pixels[:,:,3]
    luminosity = 0.299 * r + 0.587 * g + 0.114 * b

    # Create alpha mask based on luminosity
    # Soft transition: ramp from 0 at threshold-30 to full at threshold+30
    low = max(0, threshold - 40)
    high = min(255, threshold + 40)

    alpha_mask = np.clip((luminosity - low) / max(1, high - low), 0, 1)

    # Make the alpha proportional to how bright the pixel is
    # Brighter = more opaque in the overlay
    brightness_factor = luminosity / 255.0
    alpha_mask = alpha_mask * brightness_factor

    # Apply the mask
    result = pixels.copy()
    result[:,:,3] = (alpha_mask * 255).astype(np.float32)

    # Convert back to image
    result_img = Image.fromarray(result.astype(np.uint8), 'RGBA')

    # Apply slight gaussian blur to smooth edges
    if blur_radius > 0:
        # Split, blur alpha, recombine
        r_ch, g_ch, b_ch, a_ch = result_img.split()
        a_ch = a_ch.filter(ImageFilter.GaussianBlur(radius=blur_radius))
        result_img = Image.merge('RGBA', (r_ch, g_ch, b_ch, a_ch))

    result_img.save(output_path, 'PNG')
    return result_img.size


def main():
    print("Extracting bright layers from menu card images...\n")

    for cfg in IMAGES:
        input_path = os.path.join(ASSETS, cfg['input'])
        output_path = os.path.join(ASSETS, cfg['output'])

        if not os.path.exists(input_path):
            print(f"  SKIP: {cfg['input']} not found")
            continue

        size = extract_bright_layer(
            input_path, output_path,
            cfg['threshold'], cfg['blur']
        )

        print(f"  OK: {cfg['description']}")
        print(f"      {cfg['input']} -> {cfg['output']} ({size[0]}x{size[1]})")

    print("\nDone! Glow layers saved in assets/")


if __name__ == '__main__':
    main()
