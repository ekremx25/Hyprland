#version 100
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    gl_FragColor = vec4(color.r * 0.9, color.g * 0.7, color.b * 0.5, color.a);
}
