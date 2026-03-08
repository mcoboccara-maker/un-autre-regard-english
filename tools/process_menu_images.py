"""
Script de traitement des 4 images du menu principal :
1. Corrige les légendes inversées
2. Ajoute un fond noir avec coins arrondis (style icon.png)
3. Sauvegarde dans assets/univers_visuel/
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

BASE = r"C:\Users\mcopc\Documents\un_autre_regard - ESSAI\assets"
OUT_DIR = os.path.join(BASE, "univers_visuel")

# Config
PADDING = 40  # Marge noire autour de l'image
CORNER_RADIUS = 48  # Rayon des coins arrondis
FONT_SIZE = 52


def create_rounded_mask(size, radius):
    """Crée un masque avec coins arrondis."""
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)],
                           radius=radius, fill=255)
    return mask


def add_black_background(img, padding, corner_radius):
    """Ajoute un fond noir autour de l'image avec coins arrondis."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    w, h = img.size

    # Recadrer légèrement pour supprimer les coins arrondis d'origine
    # (les images sources ont déjà des coins semi-transparents)
    crop_margin = 30
    cropped = img.crop((crop_margin, crop_margin, w - crop_margin, h - crop_margin))

    # Aplatir sur un fond qui correspond aux bords de l'image
    cw, ch = cropped.size
    flat = Image.new("RGB", (cw, ch), (0, 0, 0))
    flat.paste(cropped, (0, 0), cropped)

    # Canvas noir avec padding
    canvas_w = cw + 2 * padding
    canvas_h = ch + 2 * padding
    canvas = Image.new("RGB", (canvas_w, canvas_h), (0, 0, 0))

    # Créer masque coins arrondis
    mask = create_rounded_mask((cw, ch), corner_radius)

    # Coller l'image aplatie avec le masque arrondi
    canvas.paste(flat, (padding, padding), mask)

    return canvas


def fix_text_on_image(img, new_text):
    """
    Recouvre l'ancien texte avec un bandeau opaque dégradé,
    puis écrit le nouveau texte par-dessus.
    """
    w, h = img.size
    img = img.convert("RGBA")

    # Échantillonner les couleurs sur plusieurs bandes horizontales
    # pour créer un dégradé vertical réaliste
    def sample_row_color(y_pos):
        pixels = []
        for x in range(0, w, 2):
            pixels.append(img.getpixel((x, min(y_pos, h - 1))))
        avg_r = sum(p[0] for p in pixels) // len(pixels)
        avg_g = sum(p[1] for p in pixels) // len(pixels)
        avg_b = sum(p[2] for p in pixels) // len(pixels)
        return (avg_r, avg_g, avg_b)

    # Zone à recouvrir : du début du texte jusqu'en bas
    cover_top = int(h * 0.68)  # Commencer plus haut pour un dégradé doux
    solid_top = int(h * 0.76)  # Zone 100% opaque à partir d'ici

    # Créer overlay
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)

    for y in range(cover_top, h):
        # Couleur de la ligne échantillonnée juste au-dessus de la zone de texte
        row_color = sample_row_color(min(y, int(h * 0.72)))

        if y < solid_top:
            # Zone de transition : dégradé progressif
            progress = (y - cover_top) / (solid_top - cover_top)
            alpha = int(progress * progress * 255)  # Courbe quadratique
        else:
            # Zone solide : complètement opaque
            alpha = 255

        draw_ov.line([(0, y), (w, y)],
                     fill=(row_color[0], row_color[1], row_color[2], alpha))

    # Appliquer l'overlay
    img = Image.alpha_composite(img, overlay)

    # Écrire le nouveau texte
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arialbd.ttf", FONT_SIZE)
    except OSError:
        try:
            font = ImageFont.truetype("arial.ttf", FONT_SIZE)
        except OSError:
            font = ImageFont.load_default()

    # Position du texte : centré horizontalement, dans la zone basse
    text_y = int(h * 0.82)
    bbox = draw.textbbox((0, 0), new_text, font=font)
    text_w = bbox[2] - bbox[0]
    text_x = (w - text_w) // 2

    # Ombre portée forte (plusieurs passes)
    for dx in range(-4, 5):
        for dy in range(-4, 5):
            if dx * dx + dy * dy <= 16:
                draw.text((text_x + dx, text_y + dy), new_text,
                          fill=(0, 0, 0, 200), font=font)

    # Texte principal blanc
    draw.text((text_x, text_y), new_text, fill=(255, 255, 255, 255), font=font)

    return img


def process_images():
    images_config = [
        {
            "filename": "exprime_ce_qui_te_traverse.png",
            "fix_text": False,
            "new_text": None,
        },
        {
            "filename": "partage_ce_que_tu_ressens.png",
            "fix_text": False,
            "new_text": None,
        },
        {
            "filename": "mon_chemin_parcouru.png",
            "fix_text": True,
            "new_text": "Ton chemin parcouru",
        },
        {
            "filename": "connecte_toi_aux_sources.png",
            "fix_text": True,
            "new_text": "Connecte toi aux sources",
        },
    ]

    for config in images_config:
        filepath = os.path.join(BASE, config["filename"])
        print(f"Traitement de {config['filename']}...")

        img = Image.open(filepath).convert("RGBA")

        # Étape 1 : Corriger le texte si nécessaire
        if config["fix_text"]:
            print(f"  -> Correction légende : '{config['new_text']}'")
            img = fix_text_on_image(img, config["new_text"])

        # Étape 2 : Ajouter fond noir avec coins arrondis
        img = add_black_background(img, PADDING, CORNER_RADIUS)

        # Étape 3 : Convertir en RGB si nécessaire et sauvegarder
        if img.mode == "RGBA":
            final = Image.new("RGB", img.size, (0, 0, 0))
            final.paste(img, (0, 0), img)
            img = final
        out_path = os.path.join(OUT_DIR, config["filename"])
        img.save(out_path, "PNG")
        print(f"  -> Sauvegardé : {out_path} ({img.size})")

    print("\nTerminé ! 4 images traitées.")


if __name__ == "__main__":
    process_images()
