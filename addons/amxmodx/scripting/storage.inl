#include <amxmodx>
#include <fakemeta>
#include <vdf>

BOX_Save()
{	
	if(giZonesP == 0) return;
	
	new VdfTree:tree = vdf_create_tree(gszConfigDirPerMap);
	new VdfNode:root;
	new VdfNode:box;
	new VdfNode:vector;
	
	new szValue[32];
	new szID[32];
	new Float:fOrigin[3];
	
	root = vdf_get_root_node(tree);
	vdf_set_node_key(root , "Box");
	
	
	for(new i=0; i< giZonesP; i++)
	{
	
		new ent = giZones[i];
		
		pev(ent, PEV_TYPE, szValue, 31);
		pev(ent, PEV_ID, szID, 31);
		
		//Thanks Astro
		if(szValue[0] == '^0') continue;
		
		box = vdf_append_child_node(tree, root, szValue);
		
		vdf_append_child_node(tree, box, "id", szID);
		
		
		vector = vdf_append_child_node(tree, box, "origin");
		pev(ent, pev_origin, fOrigin);
		
		
		formatex(szValue, 31, "%.1f", fOrigin[0]), vdf_append_child_node(tree, vector, "X", szValue);
		formatex(szValue, 31, "%.1f", fOrigin[1]), vdf_append_child_node(tree, vector, "Y", szValue);
		formatex(szValue, 31, "%.1f", fOrigin[2]), vdf_append_child_node(tree, vector, "Z", szValue);
		
		pev(ent, pev_mins, fOrigin);
		vector = vdf_append_child_node(tree, box, "mins");
		
		formatex(szValue, 31, "%.1f", fOrigin[0]), vdf_append_child_node(tree, vector, "X", szValue);
		formatex(szValue, 31, "%.1f", fOrigin[1]), vdf_append_child_node(tree, vector, "Y", szValue);
		formatex(szValue, 31, "%.1f", fOrigin[2]), vdf_append_child_node(tree, vector, "Z", szValue);
		
		pev(ent, pev_maxs, fOrigin);
		vector = vdf_append_child_node(tree, box, "maxs");
		
		formatex(szValue, 31, "%.1f", fOrigin[0]), vdf_append_child_node(tree, vector, "X", szValue);
		formatex(szValue, 31, "%.1f", fOrigin[1]), vdf_append_child_node(tree, vector, "Y", szValue);
		formatex(szValue, 31, "%.1f", fOrigin[2]), vdf_append_child_node(tree, vector, "Z", szValue);
	}
	
	vdf_save(tree);	
}

new gszClass[32];
new gszID[32];

new gfVectorsP = 0;
new Float:gfVectors[3][3];

BOX_Load()
{
	vdf_parse(gszConfigDirPerMap, "_BOX_Load", _, "_BOX_Load_Post");
}

public _BOX_Load(const filename[], const key[], const value[], level)
{
	switch(level)
	{
		case 0:{}
		
		case 1:
		{
			if(gszClass[0])
			{
				
				BOX_Create(gszClass, gszID, gfVectors[0], gfVectors[1], gfVectors[2]);
				gszID[0] = '^0';
			}
			copy(gszClass, 31, key);
		}
		
		case 2:
		{
			if(equal(key, "origin"))
			{
				gfVectorsP = 0;
			}
			else if(equal(key, "mins"))
			{
				gfVectorsP = 1;
			}
			else if(equal(key, "maxs"))
			{
				gfVectorsP = 2;
			}
			else if(equal(key, "id"))
			{
				copy(gszID, 31, value);
			}
		}
		
		case 3:
		{
			if(equal(key, "X"))
			{
				gfVectors[gfVectorsP][0] = str_to_float(value);
			}
			else if(equal(key, "Y"))
			{
				gfVectors[gfVectorsP][1] = str_to_float(value);
			}
			else if(equal(key, "Z"))
			{
				gfVectors[gfVectorsP][2] = str_to_float(value);
			}
		}
	}
}
public _BOX_Load_Post()
{
	//Thanks Astro
	if(gszClass[0] != '^0')
		BOX_Create(gszClass, gszID, gfVectors[0], gfVectors[1], gfVectors[2]);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
