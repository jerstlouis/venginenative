#include "stdafx.h"
#include "Mesh3dInstance.h"


Mesh3dInstance::Mesh3dInstance()
{
    initTransformation();
}

Mesh3dInstance::Mesh3dInstance(TransformationManager * transmgr)
{
    Transformation = transmgr;
}


Mesh3dInstance::~Mesh3dInstance()
{
}
