#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <vdf>
#include <celltrie>

new giTypeColors[32][3];
new gszTypeClass[32][32];
new giTypes = -1;

new Trie:gTypes; 


Types_LoadList()
{
	gTypes = TrieCreate();
	
	new dp = open_dir(gszConfigFile, gszConfigFile[giConfigFile], charsmax(gszConfigFile));
	
	if(!dp) return;
	
	Types_LoadFromFile(gszConfigFile);
 
	while(next_file(dp, gszConfigFile[giConfigFile], charsmax(gszConfigFile)))
	{	
		Types_LoadFromFile(gszConfigFile);
	}
 
	close_dir(dp);
	
	
	
}
Types_LoadFromFile(const szFile[])
{
	if(szFile[giConfigFile] == '.') 
		return;
	
	vdf_open( szFile, "parse_tree" );
}


public parse_tree(const filename[], VdfTree:tree, VdfNode:node, level)
{
	static key[32];
	
	switch(level)
	{
		case 0:
		{
			giTypes++;
			
			vdf_get_node_key(node, gszTypeClass[giTypes], 31);
			
			TrieSetCell(gTypes, gszTypeClass[giTypes], giTypes );
		}
		
		case 2:
		{
			vdf_get_node_key(node, key, 31);
		
			if(equal(key, "r") || equal(key, "red"))
			{
				giTypeColors[giTypes][0] = vdf_get_node_value_num(node);
				
			}
			if(equal(key, "g") || equal(key, "green"))
			{
				giTypeColors[giTypes][1] = vdf_get_node_value_num(node);
			}
			if(equal(key, "b") || equal(key, "blue"))
			{
				giTypeColors[giTypes][2] = vdf_get_node_value_num(node);
			}
		}
		
	}
	
	return VDF_OPEN_CONTINUE
}

getTypeId(const szNetName[])
{
	new iType = -1;
	TrieGetCell(gTypes, szNetName, iType);
	
	return iType;
	
}
getTypeColor(ent, iColor[3])
{
	if(!pev_valid(ent))
		return 0;
		
	new szNetName[32];
	pev(ent, PEV_TYPE, szNetName, 31);
	
	new iType;
	if(TrieGetCell(gTypes, szNetName, iType))
	{
		iColor[0] = giTypeColors[iType][0];
		iColor[1] = giTypeColors[iType][1];
		iColor[2] = giTypeColors[iType][2];
	}
	else
	{
		
		iColor[0] = 50;
		iColor[1] = 255;
		iColor[2] = 50;
	}
	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
