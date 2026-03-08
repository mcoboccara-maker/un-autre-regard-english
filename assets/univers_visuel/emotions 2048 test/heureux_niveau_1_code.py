import cairo

def draw_icon(output_path: str):
    SIZE = 2048
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, SIZE, SIZE)
    context = cairo.Context(surface)
    context.set_antialias(cairo.ANTIALIAS_BEST)

    # Background
    pattern = cairo.RadialGradient(SIZE * 0.5, SIZE * 0.5, 0, SIZE * 0.5, SIZE * 0.5, SIZE * 0.5)
    pattern.add_color_stop_rgb(0, 245/255, 243/255, 224/255)  # #f5f3e0
    pattern.add_color_stop_rgb(1, 144/255, 224/255, 239/255)  # #90e0ef
    context.rectangle(0, 0, SIZE, SIZE)
    context.set_source(pattern)
    context.fill()

    # Face Circle
    context.arc(SIZE * 0.5, SIZE * 0.4, SIZE * 0.3, 0, 2 * 3.14159)
    context.set_source_rgb(0, 0, 0, 0)  # No fill
    context.set_line_width(SIZE * 0.03)
    context.set_source_rgb(52/255, 202/255, 202/255)  # #34caca
    context.stroke()

    # Eyes
    context.set_source_rgb(52/255, 202/255, 202/255)  # #34caca
    context.set_line_width(1)
    # Left Eye
    context.save()
    context.translate(SIZE * 0.38, SIZE * 0.35)
    context.scale(1, 0.5)
    context.arc(0, 0, SIZE * 0.02, 0, 2 * 3.14159)
    context.restore()
    context.fill()

    # Right Eye
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