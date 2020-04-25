using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoatController : MonoBehaviour
{
    public float speed = 1.0f;
    public float turnSpeed = 1.0f;

    private Vector3 targetPosition;
    private Quaternion targetRotation;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

        targetPosition = transform.position + transform.forward * Input.GetAxis("Vertical") * speed;

        transform.position = Vector3.Lerp(transform.position, targetPosition, 0.01f);

        transform.Rotate(Vector3.up * Input.GetAxis("Horizontal") * turnSpeed);


    }
}
