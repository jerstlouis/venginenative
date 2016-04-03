#pragma once
#include "TransformationManager.h"
class AbsTransformable
{
protected:
    void initTransformation();
public:
    TransformationManager *Transformation;
    virtual ~AbsTransformable()
    {
        delete Transformation;
    }
};

