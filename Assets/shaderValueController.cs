using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class shaderValueController : MonoBehaviour
{

    public Transform floatPointML;
    public Transform floatPointMR;
    public Transform floatPointB;
    Renderer rend;

    // Start is called before the first frame update
    void Start()
    {
        rend = GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {

        rend.material.SetVector("_floatPointML", floatPointML.transform.position);
        rend.material.SetVector("_floatPointMR", floatPointMR.transform.position);
        rend.material.SetVector("_floatPointB", floatPointB.transform.position);

    }

    public void setOctaves (int octaves) {

        rend.material.SetInt("_octaves", octaves);

    }

}
