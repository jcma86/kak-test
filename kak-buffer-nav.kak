define-command buffer-nav-help %{
    info -title
"Kaktree bindings" "[Movement]
j,k,arrows: move
<tab>:      fold / unfold directory
<ret>:      change root to directory / open file under cursor
<a-ret>:    open file under cursor in specific client
u:          change root to upper directory

[Display]
h: toggle hidden files
r: refresh tree

[File operations]
d: delete entry
y: yank entry path
c: copy entry
m: move entry
l: link entry
N: new entry
M: new directory

[Help]
?: display this help box"
}

