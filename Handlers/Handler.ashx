<%@ WebHandler Language="C#" Class="Handler" %>

using System;
using System.Web;
using Newtonsoft.Json;
using System.Data;
using System.Data.OleDb;
using System.Collections.Generic;
using System.Security.Claims;

public class Handler : IHttpHandler
{
    SQLClass mySql = new SQLClass();

    public void ProcessRequest(HttpContext context)
    {

        context.Response.ContentType = "text/plain";
        string Action = context.Request["Action"];
        if (context.Request.HttpMethod == "Post")
        {
            Action = context.Request.Params["Action"];
        }
        context.Response.AddHeader("Access-Control-Allow-Origin", "*");
        context.Response.AddHeader("Access-Control-Allow-Methods", "*");

        Response<string> response = new Response<string>();

        switch (Action)
        {
            case "getAllQuestions":
                string allQuestions = "SELECT * FROM questions ORDER BY id";
                DataSet questions = mySql.SQLSelect(allQuestions);

                if (questions.Tables[0].Rows.Count != 0)
                {
                    string jsonQuestionsText = JsonConvert.SerializeObject(questions);

                    context.Response.Write(jsonQuestionsText);
                }
                else
                {
                    context.Response.Write("noQuestions");
                }
                break;

            case "getAllStudents":
                string allStudents = "SELECT * FROM students ORDER BY id";
                DataSet students = mySql.SQLSelect(allStudents);

                if (students.Tables[0].Rows.Count != 0)
                {
                    string jsonStudentsText = JsonConvert.SerializeObject(students);

                    context.Response.Write(jsonStudentsText);
                }
                else
                {
                    response.message = "noStudents";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "getStudentAnswers":
                //post request
                int studentAnswersByPhone = Convert.ToInt32(context.Request["studentPhone"]);
                string selectStudentAnswers = "SELECT answersPerProfile FROM answers WHERE answers.phone = " + studentAnswersByPhone;
                DataSet answersByStudent = mySql.SQLSelect(selectStudentAnswers);

                if (answersByStudent.Tables[0].Rows.Count != 0)
                {
                    DataSet getUserAnswers = mySql.SQLSelect(selectStudentAnswers);

                    //user exist and responde the questionary
                    response.statusCode = 200;
                    //response.message = (getUserAnswers.Tables[0].Rows[0]["answersPerProfile"]).ToString();
                    string jsonStudentsAnswers = JsonConvert.SerializeObject(getUserAnswers.Tables[0].Rows[0]["answersPerProfile"]);
                    context.Response.Write(jsonStudentsAnswers);
                }
                break;
            case "getStudentLatestResults":
                //post request
                int studentLatestResultsByPhone = Convert.ToInt32(context.Request["studentPhone"]);
                string selectStudentLatestResults = "SELECT latestResults FROM answers WHERE answers.phone = " + studentLatestResultsByPhone;
                DataSet lattestResultsByStudent = mySql.SQLSelect(selectStudentLatestResults);

                if (lattestResultsByStudent.Tables[0].Rows.Count != 0)
                {
                    DataSet getUserLatestResults = mySql.SQLSelect(selectStudentLatestResults);

                    //user exist and responde the questionary
                    response.statusCode = 200;
                    //response.message = (getUserAnswers.Tables[0].Rows[0]["answersPerProfile"]).ToString();
                    string jsonStudentsLatestResults = JsonConvert.SerializeObject(getUserLatestResults.Tables[0].Rows[0]["latestResults"]);
                    context.Response.Write(jsonStudentsLatestResults);
                }
                break;

            case "getAllManagers":
                string allManagers = "SELECT * FROM managers ORDER BY id";
                DataSet managers = mySql.SQLSelect(allManagers);

                if (managers.Tables[0].Rows.Count != 0)
                {
                    string jsonStudentsText = JsonConvert.SerializeObject(managers);

                    context.Response.Write(jsonStudentsText);
                }
                else
                {
                    context.Response.Write("noManagers");
                }
                break;

            case "loginUser":
                string userPhone = context.Request["phone"];

                string queryUserExist = "SELECT * FROM students WHERE students.phone = " + userPhone;
                //string queryUserInAnswers = "SELECT * FROM answers WHERE answers.phone = " + userPhone;
                string queryAnswers = "SELECT answersPerProfile FROM answers WHERE answers.phone = " + userPhone;

                DataSet usersStudents = mySql.SQLSelect(queryUserExist);

                if (usersStudents.Tables[0].Rows.Count != 0)
                {
                    DataSet usersAnswers = mySql.SQLSelect(queryAnswers);

                    if (usersAnswers.Tables[0].Rows.Count != 0 && usersAnswers.Tables[0].Rows[0]["answersPerProfile"].ToString() != "")
                    {
                        DataSet selectedUserAnswers = mySql.SQLSelect(queryAnswers);

                        //user exist and responde the questionary
                        response.message = (selectedUserAnswers.Tables[0].Rows[0]["answersPerProfile"]).ToString();
                        response.data = new flexyBL.JwtManager().GenerateToken(userPhone, "endQuest", 60);
                        response.statusCode = 777;
                    }
                    else
                    {
                        //user exist and didnt responde the questionary
                        response.data = new flexyBL.JwtManager().GenerateToken(userPhone, "startQuest", 60);

                        //why this?
                        var claims = new flexyBL.JwtManager().GetPrincipal(response.data);

                        response.statusCode = 200;
                    }

                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                else
                {
                    //user doesn't exist
                    response.statusCode = 999;
                    response.message = "משתמש לא קיים";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "loginManager":
                string userName = context.Request["userName"];
                string userPassword = context.Request["userPassword"];

                string queryUserName = "SELECT * FROM managers WHERE managers.userName = '" + userName + "'";
                string queryUserPassword = "SELECT * FROM managers WHERE managers.password = '" + userPassword + "'";
                string queryUserRole = "SELECT role FROM managers WHERE managers.userName = '" + userName + "'";

                DataSet userManagers = mySql.SQLSelect(queryUserName);
                DataSet checkUserPassword = mySql.SQLSelect(queryUserPassword);

                //check if userName and password exist
                if (userManagers.Tables[0].Rows.Count != 0 && checkUserPassword.Tables[0].Rows.Count != 0)
                {
                    DataSet userRole = mySql.SQLSelect(queryUserRole);
                    string role = (userRole.Tables[0].Rows[0]["role"]).ToString();
                    if (role == "user")
                    {
                        response.data = new flexyBL.JwtManager().GenerateToken(userName, "user", 60);
                    }
                    else if (role == "admin")
                    {
                        response.data = new flexyBL.JwtManager().GenerateToken(userName, "admin", 60);
                    }
                    response.statusCode = 200;
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                else
                {
                    //userName or password not match
                    response.statusCode = 999;
                    response.message = "משתמש לא קיים או סיסמא לא נכונה";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "postQuestionaryByUser":
                string studentToken = context.Request["token"];
                var simplePrinciple = new flexyBL.JwtManager().GetPrincipal(studentToken);

                if (simplePrinciple != null)
                {
                    var identity = simplePrinciple.Identity as ClaimsIdentity;
                    var phone = identity.FindFirst(ClaimTypes.Name);
                    string studentAnswers = context.Request["answers"];
                    string latestResults = context.Request["latestResults"];
                    string totalVisual = context.Request["totalVisual"];
                    string totalMovement = context.Request["totalMovement"];
                    string totalAuditory = context.Request["totalAuditory"];

                    string queryCheckUserAnswersPhone = "SELECT answers.phone FROM answers WHERE answers.phone = " + phone.Value;
                    DataSet fromSqlCheckUserAnswersPhone = mySql.SQLSelect(queryCheckUserAnswersPhone);

                    if (fromSqlCheckUserAnswersPhone.Tables[0].Rows.Count == 0)
                    {
                        string queryAddStudentAnswers = "INSERT INTO answers (answersPerProfile, phone, latestResults) VALUES ('" + studentAnswers + "'," + phone.Value + ",'" + latestResults + "')";
                        mySql.SQLChange(queryAddStudentAnswers);

                        string updateUserExamsResults = "UPDATE students SET totalVisual=" + totalVisual + ", totalMovement=" + totalMovement + ", totalAuditory=" + totalAuditory + " WHERE students.phone = " + phone.Value;
                        mySql.SQLChange(updateUserExamsResults);

                        string updateUserFinishedExamBool = "UPDATE students SET questionaryAnswered=" + true + " WHERE students.phone = " + phone.Value;
                        mySql.SQLChange(updateUserFinishedExamBool);

                        //upload answers success
                        response.statusCode = 200;
                        response.message = "תשובות העלו בהצלחה";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                    else
                    {
                        string queryCheckUserAnswersEmpty = "SELECT answers.answersPerProfile FROM answers WHERE answers.phone = " + phone.Value;
                        DataSet fromSqlCheckUserAnswersEmpty = mySql.SQLSelect(queryCheckUserAnswersEmpty);

                        if (fromSqlCheckUserAnswersEmpty.Tables[0].Rows.Count != 0)
                        {
                            string queryGetLatestResultsFromTable = "SELECT answers.latestResults FROM answers WHERE answers.phone = " + phone.Value;
                            DataSet fromSqlGetLatestResultsFromTable = mySql.SQLSelect(queryGetLatestResultsFromTable);

                            //latest results from table
                            string temp = (fromSqlGetLatestResultsFromTable.Tables[0].Rows[0]["latestResults"]).ToString();
                            latestResults = latestResults + "," + temp;

                            //change to update
                            string queryUpdateStudentAnswers = "UPDATE answers SET answersPerProfile='" + studentAnswers + "', latestResults='" + latestResults + "' WHERE answers.phone = " + phone.Value;
                            mySql.SQLChange(queryUpdateStudentAnswers);

                            string updateUserExamsResults = "UPDATE students SET questionaryAnswered=" + true + ", totalVisual=" + totalVisual + ", totalMovement=" + totalMovement + ", totalAuditory=" + totalAuditory + " WHERE students.phone = " + phone.Value;
                            mySql.SQLChange(updateUserExamsResults);

                            //upload answers success
                            response.statusCode = 200;
                            response.message = "תשובות העלו בהצלחה";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                        else
                        {
                            //upload answers error
                            response.statusCode = 777;
                            response.message = "תלמיד זה כבר ענה לשאלון";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                    }
                }
                else
                {
                    //upload answers error
                    response.statusCode = 401;
                    response.message = "שיגאה בהעלה תשובות";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "addUpdateStudentProfile":
                string studentProfileToken = context.Request["token"];
                var studentProfileSimplePrinciple = new flexyBL.JwtManager().GetPrincipal(studentProfileToken);

                if (studentProfileSimplePrinciple != null)
                {
                    int studentId = Convert.ToInt32(context.Request["id"]);
                    string studentFirstName = context.Request["firstName"];
                    string studentLastName = context.Request["lastName"];
                    int studentPhone = Convert.ToInt32(context.Request["phone"]);
                    string studentSchool = context.Request["school"];
                    string studentYear = context.Request["year"];
                    string studentProgress = context.Request["studentProgress"];

                    if (studentId != 0)
                    {
                        //update existing student
                        string selectUpdateStudentById = "SELECT * FROM students WHERE students.id =" + studentId;
                        DataSet fromSqlUpdateStudentProfile = mySql.SQLSelect(selectUpdateStudentById);

                        if (fromSqlUpdateStudentProfile.Tables[0].Rows.Count != 0)
                        {
                            string updateStudentProfileQuery = "UPDATE students SET [firstName] = '" + studentFirstName + "', [lastName] = '" + studentLastName + "', [phone] = " + studentPhone + ", [school] = '" + studentSchool + "', [year] = '" + studentYear + "', [studentProgress] = '" + studentProgress + "' WHERE students.id =" + studentId;

                            mySql.SQLChange(updateStudentProfileQuery);

                            //upload profile success
                            response.statusCode = 200;
                            response.message = "תלמיד עודכן בהצלחה";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                        else
                        {
                            //upload profile error
                            response.statusCode = 401;
                            response.message = "שגיאה בעדכון תלמיד נסה שוב";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                    }
                    else
                    {
                        //add new student
                        string newStudentProgress = "כאן יהיה כתוב התקדמות של התלמיד";
                        string checkExistingStudentByPhone = "SELECT students.phone FROM students WHERE students.phone =" + studentPhone;
                        DataSet fromSqlCheckStudentExisting = mySql.SQLSelect(checkExistingStudentByPhone);

                        if (fromSqlCheckStudentExisting.Tables[0].Rows.Count == 0)
                        {
                            string insertNewManager = "INSERT INTO students (firstName, lastName, phone, school, [year], studentProgress) VALUES ('" + studentFirstName + "','" + studentLastName + "','" + studentPhone + "','" + studentSchool + "','" + studentYear + "','" + newStudentProgress + "')";
                            mySql.SQLChange(insertNewManager);

                            //new student success
                            response.statusCode = 200;
                            response.message = "תלמיד הוסף בהצלחה";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                        else
                        {
                            //new student error
                            response.statusCode = 401;
                            response.message = "קיים תלמיד עם אותו מספר טלפון";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                    }
                }
                else
                {
                    //add or update student error - token
                    response.statusCode = 401;
                    response.message = "שגיאה בהוספה/עדכון תלמיד";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "addUpdateManagerProfile":
                string managerProfileToken = context.Request["token"];
                var managerProfileSimplePrinciple = new flexyBL.JwtManager().GetPrincipal(managerProfileToken);

                if (managerProfileSimplePrinciple != null)
                {
                    int managerId = Convert.ToInt32(context.Request["id"]);
                    string managerFirstName = context.Request["firstName"];
                    string managerLastName = context.Request["lastName"];
                    string managerUserName = context.Request["userName"];
                    int managerPhone = Convert.ToInt32(context.Request["phone"]);
                    string managerPassword = context.Request["password"];
                    string managerRole = "user";

                    if (managerId != 0)
                    {
                        //update existing manager
                        string selectManagerId = "SELECT * FROM managers WHERE managers.id =" + managerId;
                        DataSet fromSqlManagerId = mySql.SQLSelect(selectManagerId);

                        if (fromSqlManagerId.Tables[0].Rows.Count != 0)
                        {
                            string updateManagerProfile = "UPDATE managers SET [firstName] = '" + managerFirstName + "', [lastName] = '" + managerLastName + "', [userName] = '" + managerUserName + "', [phone] = " + managerPhone + ", [password] ='" + managerPassword + "' WHERE managers.id =" + managerId;
                            mySql.SQLChange(updateManagerProfile);

                            //upload manager success
                            response.statusCode = 200;
                            response.message = "משתמש עודכן בהצלחה";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                        else
                        {
                            //upload manager error
                            response.statusCode = 401;
                            response.message = "שגיאה בעדכון משתמש נסה שוב";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                    }
                    else
                    {
                        //add new manager
                        string checkExistingUserName = "SELECT managers.userName FROM managers WHERE managers.userName ='" + managerUserName + "'";
                        DataSet fromSqlCheckManagerUserName = mySql.SQLSelect(checkExistingUserName);

                        if (fromSqlCheckManagerUserName.Tables[0].Rows.Count == 0)
                        {
                            string insertNewManager = "INSERT INTO managers (firstName, lastName, userName, phone, [password], [role]) VALUES ('" + managerFirstName + "','" + managerLastName + "','" + managerUserName + "'," + managerPhone + ",'" + managerPassword + "','" + managerRole + "')";
                            mySql.SQLChange(insertNewManager);

                            //new manager success
                            response.statusCode = 200;
                            response.message = "משתמש הוסף בהצלחה";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                        else
                        {
                            //new manager error
                            response.statusCode = 401;
                            response.message = "שם משתמש קיים";
                            context.Response.Write(JsonConvert.SerializeObject(response));
                        }
                    }
                }
                else
                {
                    //add or update manager error - token
                    response.statusCode = 401;
                    response.message = "שגיאה בהוספה/עדכון משתמש";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "deleteManager":
                string deleteManagerProfileToken = context.Request["token"];
                var deleteManagerProfileSimplePrinciple = new flexyBL.JwtManager().GetPrincipal(deleteManagerProfileToken);

                if (deleteManagerProfileSimplePrinciple != null)
                {
                    int deleteManagerId = Convert.ToInt16(context.Request["id"]);

                    string selectDeleteManagerId = "SELECT * FROM managers WHERE managers.id = " + deleteManagerId;
                    DataSet fromSqlDeleteManagerId = mySql.SQLSelect(selectDeleteManagerId);

                    if (fromSqlDeleteManagerId.Tables[0].Rows.Count != 0)
                    {
                        string deleteManagerQuery = "DELETE FROM managers WHERE managers.id =" + deleteManagerId;
                        mySql.SQLChange(deleteManagerQuery);

                        //manager deleted success
                        response.statusCode = 200;
                        response.message = "משתמש נמחק בהצלחה";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                    else
                    {
                        //manager deleted error
                        response.statusCode = 401;
                        response.message = "שגיאה במחיקת משתמש";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                }
                else
                {
                    //delete manager error - token
                    response.statusCode = 401;
                    response.message = "שגיאה במחיקה משתמש";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;

            case "deleteStudent":
                string deleteStudentProfileToken = context.Request["token"];
                var deleteStudentProfileSimplePrinciple = new flexyBL.JwtManager().GetPrincipal(deleteStudentProfileToken);

                if (deleteStudentProfileSimplePrinciple != null)
                {
                    int deleteStudentPhone = Convert.ToInt32(context.Request["phone"]);

                    string selectDeleteStudentPhone = "SELECT * FROM students WHERE students.phone = " + deleteStudentPhone;
                    DataSet fromSqlDeleteStudentPhone = mySql.SQLSelect(selectDeleteStudentPhone);

                    if (fromSqlDeleteStudentPhone.Tables[0].Rows.Count != 0)
                    {
                        string selectDeleteStudentAnswers = "SELECT * FROM answers WHERE answers.phone = " + deleteStudentPhone;
                        DataSet fromSqlDeleteStudentAnswers = mySql.SQLSelect(selectDeleteStudentAnswers);

                        if (fromSqlDeleteStudentAnswers.Tables[0].Rows.Count != 0)
                        {
                            string deleteStudentAnswersQuery = "DELETE FROM answers WHERE answers.phone =" + deleteStudentPhone;
                            mySql.SQLChange(deleteStudentAnswersQuery);
                        }

                        string deleteStudentQuery = "DELETE FROM students WHERE students.phone =" + deleteStudentPhone;
                        mySql.SQLChange(deleteStudentQuery);

                        //student deleted success
                        response.statusCode = 200;
                        response.message = "תלמיד נמחק בהצלחה";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                    else
                    {
                        //student deleted error - token
                        response.statusCode = 401;
                        response.message = "שגיאה במחיקת תלמיד";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                }
                else
                {
                    //delete student error - token
                    response.statusCode = 401;
                    response.message = "שגיאה במחיקה תלמיד";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;
            case "resetQuestionaryPerStudent":
                string resetQuestinaryPerStudentToken = context.Request["token"];
                var resetQuestinaryPerStudentSimplePrinciple = new flexyBL.JwtManager().GetPrincipal(resetQuestinaryPerStudentToken);

                if (resetQuestinaryPerStudentSimplePrinciple != null)
                {
                    int resetQuestinaryByPhone = Convert.ToInt32(context.Request["phone"]);

                    string selectResetQuestStudentPhone = "SELECT answersPerProfile FROM answers WHERE answers.phone = " + resetQuestinaryByPhone;
                    DataSet fromSqlDeleteStudentPhone = mySql.SQLSelect(selectResetQuestStudentPhone);

                    if (fromSqlDeleteStudentPhone.Tables[0].Rows.Count != 0)
                    {
                        string resetAnswersPerStudent = "UPDATE answers SET answersPerProfile = NULL WHERE answers.phone =" + resetQuestinaryByPhone;
                        mySql.SQLChange(resetAnswersPerStudent);

                        string resetStudentExamBool = "UPDATE students SET questionaryAnswered =" + false + " WHERE students.phone = " + resetQuestinaryByPhone;
                        mySql.SQLChange(resetStudentExamBool);

                        //student deleted success
                        response.statusCode = 200;
                        response.message = "אבחון אופס בהצלחה";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                    else
                    {
                        //student deleted success
                        response.statusCode = 401;
                        response.message = "שגיאה באיפוס נסה שוב";
                        context.Response.Write(JsonConvert.SerializeObject(response));
                    }
                }
                else
                {
                    //reset questionary error - token
                    response.statusCode = 401;
                    response.message = "שגיאה באיפוס אבחון";
                    context.Response.Write(JsonConvert.SerializeObject(response));
                }
                break;
        }
    }

    public bool IsReusable
    {
        get
        {
            return true;
        }
    }
}