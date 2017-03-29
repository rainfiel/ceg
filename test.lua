
local struct = require "ceg.struct"

local code = [[
#ifndef EJOY_2D_SPRITE_PACK_H
#define EJOY_2D_SPRITE_PACK_H

#include <lua.h>
#include <stdint.h>

typedef signed char        int8_t;
typedef short              int16_t;
typedef signed int16_t     int16_tt;
typedef int                int32_t;
typedef long long          int64_t;
typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int_least8_t;
typedef short              int_least16_t;
typedef int                int_least32_t;
typedef long long          int_least64_t;
typedef unsigned char      uint_least8_t;
typedef unsigned short     uint_least16_t;
typedef unsigned int       uint_least32_t;
typedef unsigned long long uint_least64_t;

typedef signed char        int_fast8_t;
typedef int                int_fast16_t;
typedef int                int_fast32_t;
typedef long long          int_fast64_t;
typedef unsigned char      uint_fast8_t;
typedef unsigned int       uint_fast16_t;
typedef unsigned int       uint_fast32_t;
typedef unsigned long long uint_fast64_t;

#define TYPE_EMPTY 0
#define TYPE_PICTURE 1
#define TYPE_ANIMATION 2
#define TYPE_POLYGON 3
#define TYPE_LABEL 4
#define TYPE_PANNEL 5
#define TYPE_ANCHOR 6
#define TYPE_MATRIX 7

#define ANCHOR_ID 0xffff
#define SCREEN_SCALE 16

struct matrix {
	/* The matrix format is :
	 *
	 * | m[0] m[1] 0 |
	 * | m[2] m[3] 0 |
	 * | m[4] m[5] 1 |
	 *
	 * The format of the coordinates of a point is:
	 *
	 * | x y 1 |
	 *
	 * So, if you want to transform a point p with a matrix m, do:
	 *
	 * p * m
	 *
	 */
	int m[6];
};

typedef uint32_t offset_t;
typedef uint16_t uv_t;

#define SIZEOF_MATRIX (sizeof(struct matrix))

struct pack_pannel {
	int width;
	int height;
	int scissor;
};

#define SIZEOF_PANNEL (sizeof(struct pack_pannel))

struct pack_label {
	uint32_t color;
	int width;
	int height;
	int align;
	int size;
	int edge;
    int space_h;
    int space_w;
    int auto_scale;
};

#define SIZEOF_LABEL (sizeof(struct pack_label))

struct pack_quad {
	int texid;
	uv_t texture_coord[8];
	int32_t screen_coord[8];
};

#define SIZEOF_QUAD (sizeof(struct pack_quad))

struct pack_picture {
	int n;
	struct pack_quad rect[1];
};

#define SIZEOF_PICTURE (sizeof(struct pack_picture) - sizeof(struct pack_quad))

struct pack_poly_data {
	offset_t texture_coord;	// uv_t *
	offset_t screen_coord;	// int32_t *
	int texid;
	int n;
};

#define SIZEOF_POLY (sizeof(struct pack_poly_data))

struct pack_polygon_data {
	int n;
	struct pack_poly_data poly[1];
};

#define SIZEOF_POLYGON (sizeof(struct pack_polygon_data) - sizeof(struct pack_poly_data))

struct sprite_trans {
	struct matrix * mat;
	uint32_t color;
	uint32_t additive;
	int program;
};

struct sprite_trans_data {
	offset_t mat;
	uint32_t color;
	uint32_t additive;
};

#define SIZEOF_TRANS (sizeof(struct sprite_trans_data))

struct pack_part {
	struct sprite_trans_data t;
	int16_t component_id;
	int16_t touchable;
};

#define SIZEOF_PART (sizeof(struct pack_part))

struct pack_frame {
	offset_t part;	// struct pack_part *
	int n;
};

#define SIZEOF_FRAME (sizeof(struct pack_frame))

struct pack_action {
	offset_t name;	// const char *
	int16_t number;
	int16_t start_frame;
};

#define SIZEOF_ACTION (sizeof(struct pack_action))

struct pack_component {
	offset_t name;	// const char *
	int id;
};

#define SIZEOF_COMPONENT (sizeof(struct pack_component))

struct pack_animation {
	offset_t frame;	// struct pack_frame *
	offset_t action;	// struct pack_action *
	int frame_number;
	int action_number;
	int component_number;
	struct pack_component component[1];
};

#define SIZEOF_ANIMATION (sizeof(struct pack_animation) - sizeof(struct pack_component))

struct sprite_pack {
	offset_t type;	// uint8_t *
	offset_t data;	// void **
	int n;
	int tex[2];
};

#define SIZEOF_PACK (sizeof(struct sprite_pack) - 2 * sizeof(int))

int ejoy2d_spritepack(lua_State *L);
void dump_pack(struct sprite_pack *pack);

#define OFFSET_TO_POINTER(t, pack, off) ((off == 0) ? NULL : (t*)((uintptr_t)(pack) + (off)))
#define OFFSET_TO_STRING(pack, off) ((const char *)(pack) + (off))
#define POINTER_TO_OFFSET(pack, ptr) ((ptr == NULL) ? 0 : (offset_t)((uintptr_t)(ptr) - (uintptr_t)pack))

#ifndef ejoy_2d_particle_h
#define ejoy_2d_particle_h

#include <lua.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "matrix.h"


#define CC_DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) * 0.01745329252f) // PI / 180
#define CC_RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) * 57.29577951f) // PI * 180

#define PARTICLE_MODE_GRAVITY 0
#define PARTICLE_MODE_RADIUS 1

#define POSITION_TYPE_FREE 0
#define POSITION_TYPE_RELATIVE 1
#define POSITION_TYPE_GROUPED 2

/** The Particle emitter lives forever */
#define DURATION_INFINITY (-1)

/** The starting size of the particle is equal to the ending size */
#define START_SIZE_EQUAL_TO_END_SIZE (-1)

/** The starting radius of the particle is equal to the ending radius */
#define START_RADIUS_EQUAL_TO_END_RADIUS (-1)

struct point {
	float x;
	float y;
};

struct color4f {
	float r;
	float g;
	float b;
	float a;
};

struct particle {
	struct point pos;
	struct point startPos;
	struct matrix emitMatrix;

	struct color4f color;
	struct color4f deltaColor;
	uint32_t color_val;

	float size;
	float deltaSize;

	float rotation;
	float deltaRotation;

	float timeToLive;

	union {
		//! Mode A: gravity, direction, radial accel, tangential accel
		struct {
			struct point dir;
			float radialAccel;
			float tangentialAccel;
		} A;

		//! Mode B: radius mode
		struct {
			float angle;
			float degreesPerSecond;
			float radius;
			float deltaRadius;
		} B;
	} mode;
};

struct particle_config {
	/** Switch between different kind of emitter modes:
	 - kParticleModeGravity: uses gravity, speed, radial and tangential acceleration
	 - kParticleModeRadius: uses radius movement + rotation
	 */
	int emitterMode;

	union {
		// Different modes
		//! Mode A:Gravity + Tangential Accel + Radial Accel
		struct {
			/** Gravity value. Only available in 'Gravity' mode. */
			struct point gravity;
			/** speed of each particle. Only available in 'Gravity' mode.  */
			float speed;
			/** speed variance of each particle. Only available in 'Gravity' mode. */
			float speedVar;
			/** tangential acceleration of each particle. Only available in 'Gravity' mode. */
			float tangentialAccel;
			/** tangential acceleration variance of each particle. Only available in 'Gravity' mode. */
			float tangentialAccelVar;
			/** radial acceleration of each particle. Only available in 'Gravity' mode. */
			float radialAccel;
			/** radial acceleration variance of each particle. Only available in 'Gravity' mode. */
			float radialAccelVar;
			/** set the rotation of each particle to its direction Only available in 'Gravity' mode. */
			bool rotationIsDir;
		} A;

		//! Mode B: circular movement (gravity, radial accel and tangential accel don't are not used in this mode)
		struct {
			/** The starting radius of the particles. Only available in 'Radius' mode. */
			float startRadius;
			/** The starting radius variance of the particles. Only available in 'Radius' mode. */
			float startRadiusVar;
			/** The ending radius of the particles. Only available in 'Radius' mode. */
			float endRadius;
			/** The ending radius variance of the particles. Only available in 'Radius' mode. */
			float endRadiusVar;
			/** Number of degrees to rotate a particle around the source pos per second. Only available in 'Radius' mode. */
			float rotatePerSecond;
			/** Variance in degrees for rotatePerSecond. Only available in 'Radius' mode. */
			float rotatePerSecondVar;
		} B;
	} mode;

	//Emitter name
//    std::string _configName;

	// color modulate
	//    BOOL colorModulate;

	int srcBlend;
	int dstBlend;

	/** How many seconds the emitter will run. -1 means 'forever' */
	float duration;
	struct matrix* emitterMatrix;
	/** sourcePosition of the emitter */
	struct point sourcePosition;
	/** Position variance of the emitter */
	struct point posVar;
	/** life, and life variation of each particle */
	float life;
	/** life variance of each particle */
	float lifeVar;
	/** angle and angle variation of each particle */
	float angle;
	/** angle variance of each particle */
	float angleVar;

	/** start size in pixels of each particle */
	float startSize;
	/** size variance in pixels of each particle */
	float startSizeVar;
	/** end size in pixels of each particle */
	float endSize;
	/** end size variance in pixels of each particle */
	float endSizeVar;
	/** start color of each particle */
	struct color4f startColor;
	/** start color variance of each particle */
	struct color4f startColorVar;
	/** end color and end color variation of each particle */
	struct color4f endColor;
	/** end color variance of each particle */
	struct color4f endColorVar;
	//* initial angle of each particle
	float startSpin;
	//* initial angle of each particle
	float startSpinVar;
	//* initial angle of each particle
	float endSpin;
	//* initial angle of each particle
	float endSpinVar;
	/** emission rate of the particles */
	float emissionRate;
	/** maximum particles of the system */
	int totalParticles;
	/** conforms to CocosNodeTexture protocol */
//	Texture2D* _texture;
	/** conforms to CocosNodeTexture protocol */
//	BlendFunc _blendFunc;
	/** does the alpha value modify color */
//	bool opacityModifyRGB;
	/** does FlippedY variance of each particle */
//	int yCoordFlipped;

	/** particles movement type: Free or Grouped
	 @since v0.8
	 */
	int positionType;
};

struct particle_system {
	//! time elapsed since the start of the system (in seconds)
	float elapsed;
	float edge;

	//! Array of particles
	struct particle *particles;
	struct matrix *matrix;

	//! How many particles can be emitted per second
	float emitCounter;

	//!  particle idx
	//int particleIdx;

	// Number of allocated particles
	int allocatedParticles;

	/** Is the emitter active */
	bool isActive;

	/* Is the system has particle alive */
	bool isAlive;

	/** Quantity of particles that are being simulated at the moment */
	int particleCount;

	struct particle_config *config;
};

#endif

struct anchor_data {
	struct particle_system *ps;
	struct pack_picture *pic;
	struct matrix mat;
};

struct sprite {
	struct sprite * parent;
	struct sprite_pack * pack;
	uint16_t type;
	uint16_t id;
	struct sprite_trans t;
	union {
		struct pack_animation *ani;
		struct pack_picture *pic;
		struct pack_polygon_data *poly;
		struct pack_label *label;
		struct pack_pannel *pannel;
		struct matrix *mat;
	} s;
	struct matrix mat;
	int start_frame;
	int total_frame;
	int frame;
	int flags;
	const char *name;	// name for parent
	struct material *material;
	union {
		struct sprite * children[1];
		struct rich_text * rich_text;
		int scissor;
		struct anchor_data *anchor;
		struct particle_system *ps;
	} data;
};

#endif

]]

return struct.parse(code)