#include "Level.h"
#include <ResourceLoader.hpp>
#include <MultiMeshInstance2D.hpp>
#include <algorithm>
#include <assert.h>

const Rect2 SUB_PLACEMENT(30, 120, 860, 770);
const int MINEFIELD_START = 1000;
const float TOP_SPEED = 200;
const int FALL_ACCELERATION = 100;
const float GROUND_HEIGHT = 920;
const int MIN_OPERATING_Y = 88;
const int MAX_OPERATING_Y = 890;
const int SCREEN_WIDTH = 1920;
const float COLLISION_DISTANCE = 20;
const float EXPLOSION_RANGE = 50;

void Level::_register_methods()
{
    register_method("_ready", &Level::_ready);
    register_method("_process", &Level::_process);
    register_method("_physics_process", &Level::_physics_process);
    register_method("pull", &Level::pull);

    register_property("num_subs", &Level::num_subs, 0);
    register_property("num_mines", &Level::num_mines, 0);
    register_property("minefield_width", &Level::minefield_width, 0);
    register_property("mine_texture", &Level::mine_texture, Ref<Texture>());
}

void Level::_init()
{
}

void Level::_ready()
{
    rng = Ref<RandomNumberGenerator>(RandomNumberGenerator::_new());
    hud = get_node("HUD");

    ResourceLoader* loader = ResourceLoader::get_singleton();
    Ref<Texture> displacement_texture = loader->load("res://Textures/displacement_map.png");
    displacement_map = displacement_texture->get_data();
    displacement_map->lock();
    displacement_map_width = displacement_map->get_width();

    explosion_scene = loader->load("res://Explosion.tscn");

	// Place submarines

	MultiMeshInstance2D* submarines_node = (MultiMeshInstance2D*)get_node("Submarines");
	sub_multimesh = submarines_node->get_multimesh();

	sub_multimesh->set_instance_count(num_subs);
	for (int i = 0; i < num_subs; ++i)
	{
		Vector2 position(rng->randf_range(SUB_PLACEMENT.position.x, SUB_PLACEMENT.position.x + SUB_PLACEMENT.size.x),
			rng->randf_range(SUB_PLACEMENT.position.y, SUB_PLACEMENT.position.y + SUB_PLACEMENT.size.y));

		float depth = 1 - float(i) / num_subs;
		subs.emplace_back(position, depth);
		sub_multimesh->set_instance_custom_data(i, Color(depth, 1, 1, 1));
	}

	// Place mines

	MultiMeshInstance2D* mines_node = (MultiMeshInstance2D*)get_node("Mines");
	mine_multimesh = mines_node->get_multimesh();
	mine_multimesh->set_instance_count(num_mines);

	for (int i = 0; i < num_mines; ++i)
	{
		Vector2 position(rng->randf_range(MINEFIELD_START, MINEFIELD_START + minefield_width),
			rng->randf_range(SUB_PLACEMENT.position.y, SUB_PLACEMENT.position.y + SUB_PLACEMENT.size.y));

		float depth = 1 - float(i) / num_mines;
		mines.emplace_back(position, depth);
		mine_multimesh->set_instance_custom_data(i, Color(depth, 1, 1, 1));

		initial_rightmost_mine = max(initial_rightmost_mine, position.x);
	}
}

void Level::_process(float delta)
{
	// Update positions in multimeshes

	for (int i = 0; i < num_subs; ++i)
	{
		Transform2D transform(0, subs[i].position);
		sub_multimesh->set_instance_transform_2d(i, transform);
	}

	for (int i = 0; i < num_mines; ++i)
	{
		Transform2D transform(0, mines[i].position);
		mine_multimesh->set_instance_transform_2d(i, transform);
	}
}

void Level::_physics_process(float delta)
{
	displacement_map_scroll += delta;

	// Move submarines

	for (auto& sub : subs)
	{
		if (sub.destroyed)
		{
			if (sub.position.y < GROUND_HEIGHT)
			{
				// Fall
				sub.velocity.y += delta * FALL_ACCELERATION;
				sub.position += sub.velocity * delta;
				sub.position.y = clamp(sub.position.y, 0.0f, GROUND_HEIGHT);

				// Slow horizontal movement
				sub.velocity.x -= min(sub.velocity.x, delta * 5);
			}

			// Move with the ground, more or less
			sub.position.x -= delta * 100;
		}
		else
		{
			// Decelerate gradually
			float speed = sub.velocity.length();
			speed -= min(speed, delta * 5);
			sub.velocity = min(speed, TOP_SPEED) * sub.velocity.normalized();

			// Accelerate via water displacement map
			int displacement_sample_x = int(sub.position.x + displacement_map_scroll) % displacement_map_width;
			Color displacement = displacement_map->get_pixel(displacement_sample_x, sub.position.y);
			sub.velocity += Vector2(displacement.r - 0.5, displacement.g - 0.5).normalized() * delta * (3 + sub.depth * 3);

			// Update position
			sub.position += sub.velocity * delta;
			if (sub.position.y < MIN_OPERATING_Y)
			{
				sub.position.y = MIN_OPERATING_Y;
				sub.velocity.y = abs(sub.velocity.y);
			}
			else if (sub.position.y > MAX_OPERATING_Y)
			{
				sub.position.y = MAX_OPERATING_Y;
				sub.velocity.y = -abs(sub.velocity.y);
			}

			if (sub.position.x < 0)
			{
				sub.position.x = 0;
				sub.velocity.x = abs(sub.velocity.x);
			}
			else if (sub.position.x > SCREEN_WIDTH)
			{
				sub.position.x = SCREEN_WIDTH;
				sub.velocity.x = -abs(sub.velocity.x);
			}
		}
	}

	// Move mines and check collisions

	float rightmost_mine = 0;
	for (auto& mine : mines)
	{
		if (mine.destroyed)
			continue;

		mine.position.x -= delta * 40;
		rightmost_mine = max(rightmost_mine, mine.position.x);

		// Check collisions

		for (auto& sub : subs)
		{
			float dist = (sub.position - mine.position).length();
			if (dist < COLLISION_DISTANCE)
			{
				// Spawn an explosion
				Node2D* boom = (Node2D*)explosion_scene->instance();
				boom->set_position(mine.position);
				add_child(boom);

				mine.destroyed = true;

				break;
			}
		}

		// Destroy nearby subs if detonated

		if (mine.destroyed)
		{
			for (auto& sub : subs)
			{
				if (sub.destroyed)
					continue;

				float dist = (sub.position - mine.position).length();
				if (dist < EXPLOSION_RANGE)
				{
					sub.destroyed = true;
					hud->call("sub_destroyed");
				}

				mine.position.y = -100;
			}
		}

		Array args;
		args.append(1 - rightmost_mine / initial_rightmost_mine);
		hud->callv("set_progress", args);
	}
}

void Level::pull(Variant from, float magnitude)
{
	assert(from.get_type() == Variant::Type::VECTOR2);
	Vector2 position = from;

	for (auto& sub : subs)
	{
		if (sub.destroyed)
			continue;

		Vector2 delta = position - sub.position;
		sub.velocity += delta.normalized() * magnitude;
	}
}
