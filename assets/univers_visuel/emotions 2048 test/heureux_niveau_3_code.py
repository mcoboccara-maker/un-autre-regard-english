import cairo

def draw_icon(output_path: str):
    SIZE = 2048
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, SIZE, SIZE)
    context = cairo.Context(surface)
    context.set_antialias(cairo.ANTIALIAS_BEST)

    # Background gradient
    gradient = cairo.RadialGradient(SIZE * 0.5, SIZE * 0.5, 0, SIZE * 0.5, SIZE * 0.5, SIZE * 0.5)
    gradient.add_color_stop_rgb(0, 0xf5 / 255, 0xf3 / 255, 0xe0 / 255)
    gradient.add_color_stop_rgb(1, 0x90 / 255, 0xe0 / 255, 0xef / 255)
    context.set_source(gradient)
    context.rectangle(0, 0, SIZE, SIZE)
    context.fill()

    # Face circle
    context.arc(SIZE * 0.5, SIZE * 0.4, SIZE * 0.3, 0, 2 * 3.14159)
    context.set_source_rgb(0, 0, 0, 0)  # No fill color
    context.set_line_width(SIZE * 0.03)
    context.set_source_rgb(0x34 / 255, 0xca / 255, 0xca / 255)
    context.stroke()

    # Eyes
    context.set_source_rgb(0x34 / 255, 0xca / 255, 0xca / 255)
    context.set_line_width(SIZE * 0.03)
    # Left eye
    context.save()
    context.translate(SIZE * 0.38, SIZE * 0.35)
    context.scale(1, 0.5)
    context.arc(0, 0, SIZE * 0.02, 0, 2 * 3.14159)
    context.restore()
    context.fill()
    # Right eye
    context.save()
    context.translate(SIZE * 0.62, SIZE * 0.35)
    context.scale(1, 0.5)
    context.arc(0, 0, SIZE * 0.02, 0, 2 * 3.14159)
    context.restore()
    context.fill()

    # Mouth
    context.set_line_width(SIZE * 0.03)
    context.arc(SIZE * 0.5, SIZE * 0.48, SIZE * 0.15, 20 * (3.14159 / 180), 160 * (3.14159 / 180))
    context.stroke()

    surface.write_to_png(output_path)

draw_icon("heureux_icon.png")