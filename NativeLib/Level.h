#pragma once
#include "Common.h"
#include <Node2D.hpp>
#include <Texture.hpp>
#include <MultiMesh.hpp>
#include <Image.hpp>
#include <PackedScene.hpp>
#include <RandomNumberGenerator.hpp>
#include <vector>

// Used for both minesand submarines
struct OceanObject
{
    Vector2 position;
    Vector2 velocity;
    float depth = 0;
    bool destroyed = false;

    OceanObject(Vector2 position, float depth)
        : position(position), depth(depth)
    {
    }
};

class Level : public Node2D
{
    GODOT_CLASS(Level, Node2D);

    // Exposed properties
    int num_subs = 0;
    int num_mines = 0;
    int minefield_width = 0;
    Ref<Texture> mine_texture;

    Ref<PackedScene> explosion_scene;
    Ref<MultiMesh> sub_multimesh;
    Ref<MultiMesh> mine_multimesh;

    Ref<Image> displacement_map;
    int displacement_map_width = 0;
    int displacement_map_scroll = 0;

    vector<OceanObject> subs;
    vector<OceanObject> mines;
    float initial_rightmost_mine = 0;

    Node* hud = nullptr;

    Ref<RandomNumberGenerator> rng;

public:
    static void _register_methods();
    void _init();

    void _ready();
    void _process(float delta);
    void _physics_process(float delta);

    void pull(Variant from, float magnitude);

};

