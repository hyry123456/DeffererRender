using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DefferedRender
{
    public interface IPhysicsCollider
    {
        public CollsionStruct GetCollsionStruct();
    }
}