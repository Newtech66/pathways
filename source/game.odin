/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
      pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g_mem` global
      variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:math/linalg"
import rl "vendor:raylib"

Track :: enum {
	Forward,
	Up,
	Down,
}

Game_Memory :: struct {
	run: bool,
	tracks: [dynamic]Track,
	obstacles: map[[2]int]struct{}, // Odin discord - use for hashset
	forward_texture: rl.Texture,
	up_texture: rl.Texture,
	down_texture: rl.Texture,
	cart_texture: rl.Texture,
	game_over: bool,
	score: f32,
	speed: f32,

	place_track_row: int,
	place_track_col: int,

	cart_track_index: int,
	cart_track_row: int,
	cart_track_col: int,
	cart_track_t: f32,
}

g_mem: ^Game_Memory
NUMBER_OF_ROWS :: 9

update :: proc() {
	if !g_mem.game_over {
		appended := false
		if rl.IsKeyPressed(.D) {
			if !([2]int{ g_mem.place_track_row, g_mem.place_track_col } in g_mem.obstacles) &&
			!([2]int{ g_mem.place_track_row, g_mem.place_track_col + 1 } in g_mem.obstacles) {
				append(&g_mem.tracks, Track.Forward)
				appended = true
				g_mem.place_track_col += 2
			}
		}
		if rl.IsKeyPressed(.W) {
			if g_mem.place_track_row != 0 &&
			!([2]int{ g_mem.place_track_row, g_mem.place_track_col } in g_mem.obstacles) &&
			!([2]int{ g_mem.place_track_row - 1, g_mem.place_track_col } in g_mem.obstacles) {
				append(&g_mem.tracks, Track.Up)
				appended = true
				g_mem.place_track_row -= 1
				g_mem.place_track_col += 1
			}
		}
		if rl.IsKeyPressed(.S) {
			if g_mem.place_track_row != NUMBER_OF_ROWS - 1 &&
			!([2]int{ g_mem.place_track_row, g_mem.place_track_col } in g_mem.obstacles) &&
			!([2]int{ g_mem.place_track_row + 1, g_mem.place_track_col } in g_mem.obstacles) {
				append(&g_mem.tracks, Track.Down)
				appended = true
				g_mem.place_track_row += 1
				g_mem.place_track_col += 1
			}
		}
		if appended {
			for i in 0..<NUMBER_OF_ROWS {
				if rand.float32() < 0.2 {
					obstacle := [2]int{ i, g_mem.place_track_col + 50 }
					g_mem.obstacles[obstacle] = {}
				}
			}
		}
	
		dt := rl.GetFrameTime()
		g_mem.score += dt
		g_mem.speed += 2 * dt
		loop := true
		for loop {
			switch g_mem.tracks[g_mem.cart_track_index] {
				case .Forward: {
					track_length : f32 = 100.0
					if g_mem.cart_track_t + g_mem.speed * dt / track_length >= 1.0 {
						dt -= (1.0 - g_mem.cart_track_t) * track_length / g_mem.speed
						if g_mem.cart_track_index == len(g_mem.tracks) - 1 {
							g_mem.cart_track_t = 1.0
							loop = false
							g_mem.game_over = true
						} else {
							g_mem.cart_track_col += 2
							g_mem.cart_track_index += 1
							g_mem.cart_track_t = 0.0
						}
					} else {
						g_mem.cart_track_t += g_mem.speed * dt / track_length
						loop = false
					}
				}
				case .Up: {
					track_length : f32 = 25.0 * math.PI
					if g_mem.cart_track_t + g_mem.speed * dt / track_length >= 1.0 {
						dt -= (1.0 - g_mem.cart_track_t) * track_length / g_mem.speed
						if g_mem.cart_track_index == len(g_mem.tracks) - 1 {
							g_mem.cart_track_t = 1.0
							loop = false
							g_mem.game_over = true
						} else {
							g_mem.cart_track_col += 1
							g_mem.cart_track_row -= 1
							g_mem.cart_track_index += 1
							g_mem.cart_track_t = 0.0
						}
					} else {
						g_mem.cart_track_t += g_mem.speed * dt / track_length
						loop = false
					}
				}
				case .Down: {
					track_length : f32 = 25.0 * math.PI
					if g_mem.cart_track_t + g_mem.speed * dt / track_length >= 1.0 {
						dt -= (1.0 - g_mem.cart_track_t) * track_length / g_mem.speed
						if g_mem.cart_track_index == len(g_mem.tracks) - 1 {
							g_mem.cart_track_t = 1.0
							loop = false
							g_mem.game_over = true
						} else {
							g_mem.cart_track_col += 1
							g_mem.cart_track_row += 1
							g_mem.cart_track_index += 1
							g_mem.cart_track_t = 0.0
						}
					} else {
						g_mem.cart_track_t += g_mem.speed * dt / track_length
						loop = false
					}
				}
			}
		}
	}

	if rl.IsKeyPressed(.R) {
		g_mem.game_over = false
		g_mem.score = 0
		g_mem.speed = 150

		g_mem.place_track_row = NUMBER_OF_ROWS / 2
		g_mem.place_track_col = 0

		g_mem.cart_track_index = 0
		g_mem.cart_track_row = NUMBER_OF_ROWS / 2
		g_mem.cart_track_col = 0
		g_mem.cart_track_t = 0

		clear(&g_mem.obstacles)
		clear(&g_mem.tracks)
		for i in 0..<5 {
			append(&g_mem.tracks, Track.Forward)
			g_mem.place_track_col += 2
		}
	}

	if rl.IsKeyPressed(.ESCAPE) {
		g_mem.run = false
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.WHITE)

	cart_pos : [2]i32
	cart_rotation : f32
	switch g_mem.tracks[g_mem.cart_track_index] {
		case .Forward: {
			cart_pos.x = i32(g_mem.cart_track_col * 50) + i32(100.0 * g_mem.cart_track_t)
			cart_pos.y = i32(150 + g_mem.cart_track_row * 50 + 25)
			cart_rotation = 0.0
		}
		case .Up: {
			if g_mem.cart_track_t < 0.5 {
				cart_pos.x = i32(g_mem.cart_track_col * 50) + i32(25.0 * math.sin(g_mem.cart_track_t * math.PI))
				cart_pos.y = i32(150 + g_mem.cart_track_row * 50) + i32(25.0 * math.cos(g_mem.cart_track_t * math.PI))
				cart_rotation = -g_mem.cart_track_t * math.PI
			} else {
				cart_pos.x = i32(g_mem.cart_track_col * 50) + 50 - i32(25.0 * math.cos((g_mem.cart_track_t - 0.5) * math.PI))
				cart_pos.y = i32(150 + g_mem.cart_track_row * 50) - i32(25.0 * math.sin((g_mem.cart_track_t - 0.5) * math.PI))
				cart_rotation = -(1.0 - g_mem.cart_track_t) * math.PI
			}
		}
		case .Down: {
			if g_mem.cart_track_t < 0.5 {
				cart_pos.x = i32(g_mem.cart_track_col * 50) + i32(25.0 * math.sin(g_mem.cart_track_t * math.PI))
				cart_pos.y = i32(150 + g_mem.cart_track_row * 50) + 50 - i32(25.0 * math.cos(g_mem.cart_track_t * math.PI))
				cart_rotation = g_mem.cart_track_t * math.PI
			} else {
				cart_pos.x = i32(g_mem.cart_track_col * 50) + 50 - i32(25.0 * math.cos((g_mem.cart_track_t - 0.5) * math.PI))
				cart_pos.y = i32(150 + g_mem.cart_track_row * 50) + 50 + i32(25.0 * math.sin((g_mem.cart_track_t - 0.5) * math.PI))
				cart_rotation = (1.0 - g_mem.cart_track_t) * math.PI
			}
		}
	}

	w := rl.GetScreenWidth()
	h := rl.GetScreenHeight()
	for i in (-w/50)..=(w/50) {
		for j in 0..<NUMBER_OF_ROWS {
			rl.DrawRectangle(
				i32((g_mem.cart_track_col + int(i)) * 50) - cart_pos.x + 100,
				i32(150 + j * 50),
				50,
				50,
				((g_mem.cart_track_col + int(i) + j) % 2 == 0) ? { 245, 190, 132, 128 } : { 240, 171, 98, 175 }
			)
		}
	}

	curr_draw_track_row := NUMBER_OF_ROWS / 2
	curr_draw_track_col := 0
	for track in g_mem.tracks {
		switch track {
			case .Forward: {
				rl.DrawTexture(g_mem.forward_texture, i32(50 * curr_draw_track_col) - cart_pos.x + 100, i32(150 + curr_draw_track_row * 50), rl.WHITE)
				curr_draw_track_col += 2
			}
			case .Up: {
				rl.DrawTexture(g_mem.up_texture, i32(50 * curr_draw_track_col) - cart_pos.x + 100, i32(150 + curr_draw_track_row * 50 - 50), rl.WHITE)
				curr_draw_track_row -= 1
				curr_draw_track_col += 1
			}
			case .Down: {
				rl.DrawTexture(g_mem.down_texture, i32(50 * curr_draw_track_col) - cart_pos.x + 100, i32(150 + curr_draw_track_row * 50), rl.WHITE)
				curr_draw_track_row += 1
				curr_draw_track_col += 1
			}
		}
	}

	for obstacle in g_mem.obstacles {
		rl.DrawRectangle(i32(50 * obstacle[1]) - cart_pos.x + 100 + 10, i32(150 + obstacle[0] * 50) + 10, 30, 30, { 111, 63, 3, 255 })
	}

	rl.DrawRectangle(i32(g_mem.place_track_col * 50 + 10) - cart_pos.x + 100, i32(150 + g_mem.place_track_row * 50 + 10), 30, 30, { 255, 0, 0, 128 })

	rl.DrawTextureEx(
		g_mem.cart_texture,
		{
			100 - 25 * 1.414 * math.cos(f32(math.PI / 4) + cart_rotation),
			f32(cart_pos.y) - 25 * 1.414 * math.sin(f32(math.PI / 4) + cart_rotation)
		},
		cart_rotation * 180 / math.PI,
		1.0,
		rl.WHITE
	)

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("FPS: %v", rl.GetFPS()), 5, 5, 30, rl.BLACK)
	rl.DrawText(fmt.ctprintf("Score: %v", i32(g_mem.score)), 250, 5, 30, rl.BLACK)
	if g_mem.game_over {
		rl.DrawText("Game over", 500, 5, 30, rl.BLACK)
	}

	rl.EndDrawing()
}

@(export)
game_update :: proc() {
	update()
	draw()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Pathways")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		run = true,
		place_track_row = NUMBER_OF_ROWS / 2,
		cart_track_row = NUMBER_OF_ROWS / 2,
		forward_texture = rl.LoadTexture("assets/Forward.png"),
		up_texture = rl.LoadTexture("assets/Up.png"),
		down_texture = rl.LoadTexture("assets/Down.png"),
		cart_texture = rl.LoadTexture("assets/Cart.png"),
		speed = 150,
	}
	for i in 0..<5 {
		append(&g_mem.tracks, Track.Forward)
		g_mem.place_track_col += 2
	}

	game_hot_reloaded(g_mem)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g_mem.run
}

@(export)
game_shutdown :: proc() {
	delete(g_mem.obstacles)
	delete(g_mem.tracks)
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside
	// `g_mem`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
