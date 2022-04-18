using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;


public class Response<T>
{
    public int statusCode { get; set; }
    public T data { get; set; }
    public string message { get; set; }
}