
#include <lua.h>
#include <lauxlib.h>

#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>


typedef signed char        int8_t;
typedef short              int16_t;
typedef int                int32_t;
typedef long long          int64_t;
typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;


struct matrix {
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
		struct {
			struct point dir;
			float radialAccel;
			float tangentialAccel;
		} A;

		struct {
			float angle;
			float degreesPerSecond;
			float radius;
			float deltaRadius;
		} B;
	} mode;
};

struct particle_config {
	int emitterMode;

	union {
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

	int positionType;
};

struct particle_system {
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

struct union_align {
	// int size;
	char head;
	union {
		void *a;
		char b;
	} c;
	char* d;

	union {
		char e;
		int f[13];
	} g;
	short h;

	union {
		int i[3];
		long j;
	} k;

	union {
		union {
			int a;
			char b;
		} c;
		struct {
			void * d;
			char e;
		} f;
	} l;

	union {
		union {
			char a;
			union {
				void *b;
				char c;
			} d;
		} e;
		int f;
	} m;

	union {
		char a;
		char b[2];
	} n;

	void *o;
};

static int 
lunion_align(lua_State *L) {
	size_t sz = sizeof(struct union_align);
	struct union_align n;
	memset(&n, 0, sz);

	n.head = '!';
	n.c.a = 2;
	n.d = 3;

	n.g.e = '!';
	n.h = 4;

	n.k.i[0] = 5;
	n.k.i[1] = 6;
	n.k.i[2] = 7;

	n.l.f.d = 8;
	n.l.f.e = '!';

	n.m.e.d.b = 9;

	n.n.a = '!';

	n.o = 10;

	lua_pushlstring(L, (char*)&n, sz);
	return 1;
}

struct struct_align
{
	struct {
		void* a;
		char b;
	} c;
	long d;

	struct 
	{
		void* a;
		char b;
	} e;
	char f;

	struct
	{
		short a;
		char b;
	} g;
	char h;

	struct
	{
		void* a;
		char b;
	} i;
};

static int
lstruct_align(lua_State *L) {
	size_t sz = sizeof(struct struct_align);
	struct struct_align ta;
	memset(&ta, 0, sz);

	ta.c.a=0;
	ta.c.b='!';
	ta.d = 0xffffffff;

	ta.e.a=0;
	ta.e.b='!';
	ta.f='?';

	ta.g.a = 1;
	ta.g.b = '!';
	ta.h = '?';

	ta.i.a = 0;
	ta.i.b = '!';

	lua_pushlstring(L, (char*)&ta, sz);
	return 1;
}


static int
lparticle_config(lua_State *L) {
	size_t sz = sizeof(struct particle_config);
	struct particle_config* config = (struct particle_config*)lua_newuserdata(L, sz);
	memset(config, 0, sz);

	config->emitterMode = 0;
	config->mode.A.gravity.x = 1;
	config->mode.A.gravity.y = 2;
	config->mode.A.speed = 3;
	config->mode.A.speedVar = 4;
	config->mode.A.tangentialAccel = 5;
	config->mode.A.tangentialAccelVar = 6;
	config->mode.A.radialAccel = 7;
	config->mode.A.radialAccelVar = 8;
	config->mode.A.rotationIsDir = true;

	config->srcBlend = 1;
	config->dstBlend = 0x301;
	config->duration = 9;
	config->emitterMatrix = 0;
	config->sourcePosition.x = 10;
	config->sourcePosition.y = 11;
	config->posVar.x = 12;
	config->posVar.y = 13;
	config->life = 14;
	config->lifeVar = 15;
	config->angle = 16;
	config->angleVar = 17;
	config->startSize = 18;
	config->startSizeVar = 19;
	config->endSize = 20;
	config->endSizeVar = 21;


	config->endSpin = 234;

	config->totalParticles = 123;
	config->positionType = 1;

	lua_pushlstring(L, (char*)config, sz);
	return 1;
}


int
luaopen_ltest(lua_State *L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		{ "particle_config", lparticle_config },
		{ "union_align", lunion_align },
		{ "struct_align", lstruct_align },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	return 1;
}
