from PIL import Image
import glob, os, errno

orig_bright = (255, 219, 77)
orig_dark = (255, 144, 46)

def recolor(px, bright, dark):
    r, g, b, a = px
    if (r, g, b) == orig_bright:
        return tuple(bright) + (a,)
    elif (r, g, b) == orig_dark:
        return tuple(dark) + (a,)
    else:
        return px

palettes = list(Image.open('palettes.png').getdata())
palettes = zip(palettes[0::2], palettes[1::2])

for pnum, (bright, dark) in enumerate(palettes):
    pal = 'palette' + str(pnum)
    try:
        os.makedirs(pal)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise e

    for fn in glob.glob('orig/*.png'):
        im = Image.open(fn)
        w, h = im.size
        im.putdata([recolor(px, bright, dark) for px in im.getdata()])
        im.save(fn.replace('orig', pal))
