<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>企业OKR管理系统</title>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <script src="${pageContext.request.contextPath}/js/jquery-3.3.1.min.js"></script>
    <script src="${pageContext.request.contextPath}/codebase/dhtmlx.js" type="text/javascript"></script>
    <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/codebase/dhtmlx.css">
    <style>
        html, body {
            width: 100%;
            height: 100%;
            overflow: hidden;
            margin: 0;
        }
    </style>
    <script type="text/javascript">
        let myLayout1, myLayout2, myLayout3, myTabBar;
        function doOnLoad() {
            myTabBar = new dhtmlXTabBar("my_tabBar");
            myTabBar.addTab("tab1", "组织管理", null, null, true);
            myTabBar.addTab("tab2", "人员OKR管理", null, null);
            myTabBar.addTab("tab3", "部门OKR管理", null, null);
            OrganizationManagement();
            myTabBar.attachEvent("onTabClick", function (id) {
                if (id === "tab3") {
                    DepartmentOKRManagement();
                }
                else if (id === "tab2") {
                    PersonOKRManagement();
                }
            });

        }
        function checkWeight(url, data) {
            dhx.ajax.post(url, data, function (result) {
                let temp = result.xmlDoc.responseText;
                if (temp !== "") {
                    dhtmlx.alert({
                        title: "警告!⚠️",
                        type: "alert-error",
                        text: temp
                    });
                }
            });
        }

        function OrganizationManagement() {
            myLayout1 = myTabBar.tabs("tab1").attachLayout("2U");
            /*左边的布局 部门树*/
            myLayout1.cells("a").setWidth(260);
            myLayout1.cells("a").setText("部门管理");
            let myToolbarLeft = myLayout1.cells("a").attachToolbar();
            myToolbarLeft.setIconsPath("${pageContext.request.contextPath}/icons/");
            myToolbarLeft.loadStruct("${pageContext.request.contextPath}/data/toolbar.xml", function () {
            });
            let myTree = myLayout1.cells("a").attachTree();
            myTree.setImagesPath("codebase/images/");

            /*右边的的布局 人员表*/
            myLayout1.cells("b").setText("人员管理");
            let myToolbarRight = myLayout1.cells("b").attachToolbar();
            myToolbarRight.setIconsPath("${pageContext.request.contextPath}/icons/");
            myToolbarRight.loadStruct("${pageContext.request.contextPath}/data/toolbar.xml", function () {
            });
            let myGrid = myLayout1.cells("b").attachGrid();
            myGrid.setImagePath("${pageContext.request.contextPath}/codebase/images/");
            myGrid.setIconsPath("${pageContext.request.contextPath}/icons/");
            myGrid.setHeader("&nbsp;,departmentId,员工名,职位,邮箱,手机号,地址");
            myGrid.setColTypes("img,ro,ro,ro,ro,ro,ro");
            myGrid.setInitWidths("70,0,100,100,150,120,*");
            myGrid.setColAlign("center,left,left,left,left,left");
            myGrid.init();

            /*加载部门树*/
            myTree.load("${pageContext.request.contextPath}/department/departmentTree", function () {
            }, "xml");
            /*加载点击部门的员工表*/
            myTree.attachEvent("onClick", function () {
                myGrid.clearAll(false);
                myGrid.load("${pageContext.request.contextPath}/person/getPeople?id=" + myTree.getSelectedItemId(), function () {
                }, "xml");
            });

            /*添加人员*/
            function addPerson() {
                if (myTree.getSelectedItemId() == null) {
                    dhtmlx.alert("请您选择要在哪个部门添加人员");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 60, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "personName", label: "员工名", value: "", required: true},
                            {type: "input", name: "position", label: "职位", value: "", required: true},
                            {
                                type: "input",
                                name: "email",
                                label: "邮箱",
                                value: "",
                                validate: "ValidEmail",
                                required: true
                            },
                            {type: "input", name: "phone", label: "手机号", value: "", required: true},
                            {type: "input", name: "address", label: "地址", value: "", required: true}
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 100, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];
                let did = myTree.getSelectedItemId();
                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "380", "360");
                dhxWins.window("w1").center();
                w1.setText("添加人员");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "personName=" + myForm.getItemValue("personName") + "&position="
                            + myForm.getItemValue("position") + "&email=" + myForm.getItemValue("email") + "&phone="
                            + myForm.getItemValue("phone") + "&address=" + myForm.getItemValue("address") + "&departmentId=" + did;
                        console.log(data);
                        dhx.ajax.post("person/addPerson", data, function () {
                            myGrid.clearAll(false);
                            myGrid.load("person/getPeople?id=" + did, function () {
                            }, "xml");
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*删除人员*/
            function deletePerson() {
                let sid = myGrid.getSelectedRowId();
                if (sid == null) {
                    dhtmlx.alert("请选中您将要删除的员工");
                    return;
                }
                dhtmlx.confirm('主人，真的要狠心删除我吗', function (result) {
                    if (result) {
                        myGrid.load("person/deletePersonById?id=" + sid, function () {
                            myGrid.deleteRow(sid);
                        }, "xml");
                    } else {
                        dhtmlx.alert("已取消删除");
                    }
                });
            }

            /*编辑人员*/
            function editPerson() {
                let rid = myGrid.getSelectedRowId();
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 60, inputWidth: 200, position: "label-left"},
                            {
                                type: "input",
                                name: "personName",
                                label: "员工名",
                                value: myGrid.cells(rid, 2).getValue(),
                                required: true
                            },
                            {
                                type: "input",
                                name: "position",
                                label: "职位",
                                value: myGrid.cells(rid, 3).getValue(),
                                required: true
                            },
                            {
                                type: "input",
                                name: "email",
                                label: "邮箱",
                                value: myGrid.cells(rid, 4).getValue(),
                                required: true
                            },
                            {
                                type: "input",
                                name: "phone",
                                label: "手机号",
                                value: myGrid.cells(rid, 5).getValue(),
                                required: true
                            },
                            {
                                type: "input",
                                name: "address",
                                label: "地址",
                                value: myGrid.cells(rid, 6).getValue(),
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 100, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];

                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "380", "360");
                dhxWins.window("w1").center();
                w1.setText("编辑人员");
                let myForm = w1.attachForm(formData);
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "personId=" + rid + "&personName=" + myForm.getItemValue("personName") + "&position="
                            + myForm.getItemValue("position") + "&email=" + myForm.getItemValue("email") + "&phone="
                            + myForm.getItemValue("phone") + "&address=" + myForm.getItemValue("address");
                        dhx.ajax.post("person/updatePerson", data, function () {
                            myGrid.clearAll(false);
                            myGrid.load("person/getPeople?id=" + myTree.getSelectedItemId(), function () {
                            }, "xml");
                        });
                    }
                    dhxWins.window("w1").hide();
                });

            }

            /*添加部门*/
            function addDepartment() {
                let pid = myTree.getSelectedItemId();
                if (pid === '') {
                    dhtmlx.alert("请您选择要在哪个节点下添加部门");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "departmentName", label: "部门名", value: ""}
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];

                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("添加部门");
                let myForm = w1.attachForm(formData);
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "departmentName=" + encodeURI(encodeURI(myForm.getItemValue("departmentName")))
                            + "&parentId=" + pid;
                        dhx.ajax.post("department/addDepartment", data, function (result) {
                            let id = result.xmlDoc.responseText;
                            myTree.insertNewChild(pid, id, myForm.getItemValue("departmentName"), function () {
                            }, "folderClosed.gif")
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*删除部门*/
            function deleteDepartment() {
                let sid = myTree.getSelectedItemId();
                let pid = myTree.getParentId(sid);
                if (sid === '') {
                    dhtmlx.alert("请选中您将要删除的部门");
                    return;
                } else if (sid === "1") {
                    dhtmlx.alert("顶级公司不可删除的，您可以按需求修改");
                    return;
                }

                if (myTree.hasChildren(sid) === 0) {
                    if (myGrid.getRowsNum() === 0) {
                        dhtmlx.confirm('主人，真的要狠心删除我吗', function (result) {
                            if (result) {
                                let data = "id=" + sid;
                                dhx.ajax.post("department/deleteDepartmentById", data, function () {
                                    myTree.deleteItem(sid, true);
                                    /*加载父级部门的员工*/
                                    let data1 = "id=" + pid;
                                    dhx.ajax.post("person/getPeople", data1, function () {
                                    });
                                });
                            } else {
                                dhtmlx.alert("已取消删除");
                            }
                        });
                    } else {
                        dhtmlx.alert("亲，该部门下还存在员工，先删除员工");
                    }
                } else {
                    dhtmlx.alert("亲，该部门下还存在子部门，请先删除子部门");
                }
            }

            /*编辑部门*/
            function editDepartment() {
                let id = myTree.getSelectedItemId();
                if (id === '') {
                    dhtmlx.alert("请选中您将要编辑的部门");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "departmentName", label: "部门名", value: myTree.getSelectedItemText()},
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];
                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("编辑部门");
                let myForm = w1.attachForm(formData);
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {

                        let data = "departmentName=" + encodeURI(encodeURI(myForm.getItemValue("departmentName")))
                            + "&parentId=" + myTree.getParentId(id) + "&departmentId=" + id;
                        dhx.ajax.post("department/updateDepartment", data, function () {
                            myTree.setItemText(id, myForm.getItemValue("departmentName"), null);
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*给通过ToolbarLeft 部门操作*/
            myToolbarLeft.attachEvent("onClick", function (id) {
                switch (id) {
                    case 'add':
                        addDepartment();
                        break;
                    case 'delete':
                        deleteDepartment();
                        break;
                    default:
                        editDepartment();
                }
            });

            /*给通过ToolbarRight操作人员表*/
            myToolbarRight.attachEvent("onClick", function (id) {
                switch (id) {
                    case 'add':
                        addPerson();
                        break;
                    case 'delete':
                        deletePerson();
                        break;
                    default:
                        editPerson()
                }
            });
        }

        function PersonOKRManagement() {

            myLayout2 = myTabBar.tabs("tab2").attachLayout("4W");
            /*左边的布局 部门树*/
            myLayout2.cells("a").setWidth(280);
            myLayout2.cells("a").setText("部门");

            let myTree = myLayout2.cells("a").attachTree();
            myTree.setImagesPath("codebase/images/");

            /*右边的的布局 人员表*/
            myLayout2.cells("b").setText("人员");
            myLayout2.cells("b").setWidth(200);
            let personGrid = myLayout2.cells("b").attachGrid();
            personGrid.setImagePath("codebase/images/");
            personGrid.setIconsPath("icons/");
            personGrid.setHeader("&nbsp;,departmentId,员工名");
            personGrid.setColTypes("img,ro,ro");
            personGrid.setInitWidths("70,0,*");
            personGrid.setColAlign("center,left,left");
            personGrid.init();

            myLayout2.cells("c").setText("目标");
            myLayout2.cells("c").setWidth(500);
            let myToolbarLeft = myLayout2.cells("c").attachToolbar();
            myToolbarLeft.addInput("time", 4, "", 150);
            $("input").replaceWith("月份&nbsp;" +
                "<select id='month'  class='month' style='height:25px'>"
                + "<option ></option>"
                + "<option >1</option>"
                + "<option >2</option>"
                + "<option >3</option>"
                + "<option >4</option>"
                + "<option >5</option>"
                + "<option >6</option>"
                + "<option >7</option>"
                + "<option >8</option>"
                + "<option >9</option>"
                + "<option >10</option>"
                + "<option >11</option>"
                + "<option >12</option>"
                + "</select>");
            myToolbarLeft.setIconsPath("icons/");
            myToolbarLeft.loadStruct("data/toolbar.xml", function () {
            });


            let objectGrid = myLayout2.cells("c").attachGrid();
            objectGrid.setHeader("&nbsp,departmentId,目标名,权重(%),所属月份");
            objectGrid.setInitWidths("70,0,120,90,90");
            objectGrid.setColAlign("center,left,left,left,left");
            objectGrid.setColTypes("img,ro,ro,ro,ro");
            objectGrid.init();

            myLayout2.cells("d").setText("关键结果管理");
            let myToolbarRight = myLayout2.cells("d").attachToolbar();
            myToolbarRight.setIconsPath("icons/");
            myToolbarRight.loadStruct("data/toolbar.xml", function () {
            });
            let keyResultGrid = myLayout2.cells("d").attachGrid();
            keyResultGrid.setImagePath("codebase/images/");
            keyResultGrid.setIconsPath("icons/");
            keyResultGrid.setHeader("&nbsp;,objectId,关键结果名,权重(%)");
            keyResultGrid.setColTypes("img,ro,ro,ro");
            keyResultGrid.setInitWidths("70,0,120,90");
            keyResultGrid.setColAlign("center,left,left,left");
            keyResultGrid.init();

            /*加载部门树*/
            myTree.load("department/departmentTree", function () {
            }, "xml");

            /*加载点击部门的员工表*/
            myTree.attachEvent("onClick", function (id) {
                keyResultGrid.clearAll(false);
                personGrid.clearAll(false);
                objectGrid.clearAll(false);
                personGrid.load("person/getPeople?id=" + id, function () {
                }, "xml");
            });

            function loadObject(personId) {
                keyResultGrid.clearAll(false);
                objectGrid.clearAll(false);
                objectGrid.load("personObject/getPersonObjects?id=" + personId
                    + "&month=" + document.getElementById('month').selectedIndex, function () {
                }, "xml");
            }

            /*当选择人员时加载人员的目标*/
            personGrid.attachEvent("onRowSelect", function (id, ind) {
                document.getElementById('month').selectedIndex = 0;
                loadObject(id)
            });

            /*当选择人员目标时加载关键目标*/
            objectGrid.attachEvent("onRowSelect", function (id, ind) {
                loadKeyResult(id);
            });

            $(document).ready(function () {
                $(".month").change(function () {
                    let pid = personGrid.getSelectedRowId();
                    if (pid === "") {
                    } else {
                        loadObject(pid)
                    }
                });
            });

            /*给通过ToolbarLeft员工目标操作*/
            myToolbarLeft.attachEvent("onClick", function (id) {
                switch (id) {
                    case 'add':
                        addPersonObject();
                        break;
                    case 'delete':
                        deletePersonObject();
                        break;
                    case 'edit':
                        editPersonObject();
                        break;
                }
            });

            /*添加目标*/
            function addPersonObject() {
                if (personGrid.getSelectedRowId() == null) {
                    dhtmlx.alert("请您先选中，您要为哪个人添加目标");
                    return;
                }
                if (document.getElementById("month").selectedIndex === 0) {
                    dhtmlx.alert("请您先选中，您要为哪个月添加添加目标");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "objectName", label: "目标名", value: ""},
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: "",
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];

                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("添加目标");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });

                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let pid = personGrid.getSelectedRowId();
                        let data = "objectName=" + encodeURI(encodeURI(myForm.getItemValue("objectName")))
                            + "&month=" + document.getElementById('month').selectedIndex
                            + "&weight=" + encodeURI(encodeURI(myForm.getItemValue("weight")))
                            + "&personId=" + pid;
                        dhx.ajax.post("personObject/addPersonObject", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadObject(pid);
                                checkWeight("personObject/checkWeight", data);
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*删除目标*/
            function deletePersonObject() {
                let id = objectGrid.getSelectedRowId();
                if (id == null) {
                    dhtmlx.alert("请选中您将要删除的目标");
                    return;
                }
                if (keyResultGrid.getRowsNum() === 0) {
                    dhtmlx.confirm('主人，真的要狠心删除我吗', function (result) {
                        if (result) {
                            let data = "id=" + id;
                            dhx.ajax.post("personObject/deletePersonObjectById", data, function () {
                                objectGrid.deleteRow(id);
                            });
                        } else {
                            dhtmlx.alert("已取消删除");
                        }
                    });
                } else {
                    dhtmlx.alert("亲，该目标下还存在关键结果");
                }
            }

            /*编辑目标*/
            function editPersonObject() {
                let rid = objectGrid.getSelectedRowId();
                let pid = personGrid.getSelectedRowId();
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {
                                type: "input",
                                name: "objectName",
                                label: "目标名",
                                value: objectGrid.cells(rid, 2).getValue()
                            },
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: objectGrid.cells(rid, 3).getValue(),
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }

                        ]
                    },
                    {
                        type: "checkbox", checked: true, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];
                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("编辑目标");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });

                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "objectName=" + encodeURI(encodeURI(myForm.getItemValue("objectName"))) +
                            "&weight=" + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&objectId=" + rid;
                        let data1 = "personId=" + pid + "&month=" + objectGrid.cells(rid, 4).getValue();
                        dhx.ajax.post("personObject/updatePersonObject", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadObject(pid);
                                checkWeight("personObject/checkWeight", data1)
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*给通过ToolbarLeft对员工关键结果进行操作*/
            myToolbarRight.attachEvent("onClick", function (id) {
                switch (id) {
                    case 'add':
                        addKeyResult();
                        break;
                    case 'delete':
                        deleteResult();
                        break;
                    default:
                        editResult();
                }
            });

            function loadKeyResult(objectId) {
                keyResultGrid.clearAll(false);
                keyResultGrid.load("personKeyResult/getPersonKeyResultsByObjectId?id=" + objectId, function () {
                }, "xml");
            }

            /*添加关键结果*/
            function addKeyResult() {
                if (objectGrid.getSelectedRowId() == null) {
                    dhtmlx.alert("请您先选中，您要为哪目标添加关键成果");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "keyResultName", label: "关键结果名", value: "", required: true},
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: "",
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];

                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("添加关键成果");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let oid = objectGrid.getSelectedRowId();
                        let data = "keyResultName=" + encodeURI(encodeURI(myForm.getItemValue("keyResultName")))
                            + "&weight=" + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&personObjectId=" + oid;
                        dhx.ajax.post("personKeyResult/addPersonKeyResult", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadKeyResult(oid);
                                checkWeight("personKeyResult/checkWeight", data)
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*删除关键结果*/
            function deleteResult() {
                let id = keyResultGrid.getSelectedRowId();
                if (id == null) {
                    dhtmlx.alert("请选中您将要删除的关键结果");
                    return;
                }
                dhtmlx.confirm('主人，真的要狠心删除我吗', function (result) {
                    if (result) {
                        let data = "id=" + id;
                        dhx.ajax.post("personKeyResult/deletePersonKeyResultById", data, function () {
                            keyResultGrid.deleteRow(id);
                        });
                    } else {
                        dhtmlx.alert("已取消删除");
                    }
                });
            }

            /*编辑关键结果*/
            function editResult() {
                let rid = keyResultGrid.getSelectedRowId();
                let oid = objectGrid.getSelectedRowId();
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {
                                type: "input",
                                name: "keyResultName",
                                label: "关键结果名",
                                value: keyResultGrid.cells(rid, 2).getValue()
                            },
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: keyResultGrid.cells(rid, 3).getValue(),
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];
                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("编辑关键结果");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "keyResultName=" + encodeURI(encodeURI(myForm.getItemValue("keyResultName")))
                            + "&weight=" + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&keyResultId=" + rid;
                        let data1 = "personObjectId=" + oid;
                        dhx.ajax.post("personKeyResult/updatePersonKeyResult", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadKeyResult(oid);
                                checkWeight("personKeyResult/checkWeight", data1);
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }
        }

        function DepartmentOKRManagement() {

            myLayout3 = myTabBar.tabs("tab3").attachLayout("3W");
            /*左边的布局 部门树*/
            myLayout3.cells("a").setWidth(260);
            myLayout3.cells("a").setText("部门");

            let myTree = myLayout3.cells("a").attachTree();
            myTree.setImagesPath("codebase/images/");

            /*右边的的布局目标表*/
            myLayout3.cells("b").setText("目标");
            myLayout3.cells("b").setWidth(500);
            let myToolbarLeft = myLayout3.cells("b").attachToolbar();
            myToolbarLeft.setIconsPath("icons/");
            myToolbarLeft.loadStruct("data/toolbar.xml", function () {
            });
            myToolbarLeft.addInput("time", 4, "", 150);
            $("input").replaceWith("月份&nbsp;" +
                "<select id='month1'  class='month1' style='height:25px'>"
                + "<option ></option>"
                + "<option >1</option>"
                + "<option >2</option>"
                + "<option >3</option>"
                + "<option >4</option>"
                + "<option >5</option>"
                + "<option >6</option>"
                + "<option >7</option>"
                + "<option >8</option>"
                + "<option >9</option>"
                + "<option >10</option>"
                + "<option >11</option>"
                + "<option >12</option>"
                + "</select>");

            let objectGrid = myLayout3.cells("b").attachGrid();
            objectGrid.setHeader("&nbsp,departmentId,目标名,权重(%),所属月份");
            objectGrid.setInitWidths("70,0,120,90,90");
            objectGrid.setColAlign("center,left,left,left,left");
            objectGrid.setColTypes("img,ro,ro,ro,ro");
            objectGrid.init();

            myLayout3.cells("c").setText("关键结果管理");
            let myToolbarRight = myLayout3.cells("c").attachToolbar();
            myToolbarRight.setIconsPath("icons/");
            myToolbarRight.loadStruct("data/toolbar.xml", function () {
            });
            let keyResultGrid = myLayout3.cells("c").attachGrid();
            keyResultGrid.setImagePath("codebase/images/");
            keyResultGrid.setIconsPath("icons/");
            keyResultGrid.setHeader("&nbsp;,objectId,关键结果名,权重(%)");
            keyResultGrid.setColTypes("img,ro,ro,ro");
            keyResultGrid.setInitWidths("70,0,120,90");
            keyResultGrid.setColAlign("center,left,left,left");
            keyResultGrid.init();


            $(document).ready(function () {
                $(".month1").change(function () {
                    let did = myTree.getSelectedItemId();
                    if (did === "") {
                    } else {
                        loadObject(did)
                    }
                });
            });

            /*加载部门树*/
            myTree.load("department/departmentTree", function () {
            }, "xml");

            function loadObject(departmentId) {
                keyResultGrid.clearAll(false);
                objectGrid.clearAll(false);
                objectGrid.load("departmentObject/getDepartmentObjectsByDepartmentId?id=" + departmentId
                    + "&month=" + document.getElementById('month1').selectedIndex, function () {
                }, "xml");
            }

            /*点击加载部门的目标表*/
            myTree.attachEvent("onClick", function (id) {
                document.getElementById('month1').selectedIndex = 0;
                loadObject(id);
            });

            function loadKeyResult(objectId) {
                keyResultGrid.clearAll(false);
                keyResultGrid.load("departmentKeyResult/getDepartmentKeyResultsByObjectId?id=" + objectId, function () {
                }, "xml");
            }

            /*当选择目标时加载关键目标*/
            objectGrid.attachEvent("onRowSelect", function (id, ind) {
                loadKeyResult(id);
            });

            /*给通过ToolbarLeft部门目标操作*/
            myToolbarLeft.attachEvent("onClick", function (id) {
                switch (id) {
                    case 'add':
                        addDepartmentObject();
                        break;
                    case 'delete':
                        deleteDepartmentObject();
                        break;
                    default:
                        editDepartmentObject();
                }
            });

            /*添加部门目标*/
            function addDepartmentObject() {
                if (myTree.getSelectedItemId() === '') {
                    dhtmlx.alert("请您先选中，您要为哪个部门人添加目标");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "objectName", label: "目标名", value: "", required: true},
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: "",
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];

                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("添加目标");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });

                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let did = myTree.getSelectedItemId();
                        let data = "objectName=" + encodeURI(encodeURI(myForm.getItemValue("objectName")))
                            + "&month=" + document.getElementById('month1').selectedIndex
                            + "&weight=" + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&departmentId=" + did;
                        dhx.ajax.post("departmentObject/addDepartmentObject", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadObject(did);
                                checkWeight("departmentObject/checkWeight", data);
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*删除部门目标*/
            function deleteDepartmentObject() {
                let id = objectGrid.getSelectedRowId();
                if (id == null) {
                    dhtmlx.alert("请选中您将要删除的目标");
                    return;
                }
                if (keyResultGrid.getRowsNum() === 0) {
                    dhtmlx.confirm('主人，真的要狠心删除我吗', function (result) {
                        if (result) {
                            let data = "id=" + id;
                            dhx.ajax.post("departmentObject/deleteDepartmentObjectById", data, function () {
                                objectGrid.deleteRow(id);
                            });
                        } else {
                            dhtmlx.alert("已取消删除");
                        }
                    });
                } else {
                    dhtmlx.alert("亲，该目标下还存在关键结果");
                }
            }

            /*编辑部门目标*/
            function editDepartmentObject() {
                let rid = objectGrid.getSelectedRowId();
                let did = myTree.getSelectedItemId();
                if (rid == null) {
                    dhtmlx.alert("请选中您将要编辑的目标");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {
                                type: "input",
                                name: "objectName",
                                label: "目标名",
                                value: objectGrid.cells(rid, 2).getValue()
                            },
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: objectGrid.cells(rid, 3).getValue(),
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }

                        ]
                    },
                    {
                        type: "checkbox", checked: true, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];
                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("编辑目标");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });

                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "objectName=" + encodeURI(encodeURI(myForm.getItemValue("objectName"))) + "&weight="
                            + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&objectId=" + rid;
                        let data1 = "departmentId=" + did + "&month=" + objectGrid.cells(rid, 4).getValue();
                        dhx.ajax.post("departmentObject/updateDepartmentObject", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadObject(did);
                                checkWeight("departmentObject/checkWeight", data1);
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*给通过ToolbarRight对部门关键结果进行处理*/
            myToolbarRight.attachEvent("onClick", function (id) {
                switch (id) {
                    case 'add':
                        addKeyResult();
                        break;
                    case 'delete':
                        deleteResult();
                        break;
                    default:
                        editResult();
                }
            });

            /*添加部门关键结果*/
            function addKeyResult() {
                if (objectGrid.getSelectedRowId() == null) {
                    dhtmlx.alert("请您先选中，您要为哪目标添加关键成果");
                    return;
                }
                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {type: "input", name: "keyResultName", label: "关键结果名", value: "", required: true},
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: "",
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];

                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("添加关键成果");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let oid = objectGrid.getSelectedRowId();
                        let data = "keyResultName=" + encodeURI(encodeURI(myForm.getItemValue("keyResultName"))) + "&weight="
                            + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&objectId=" + oid;
                        dhx.ajax.post("departmentKeyResult/addDepartmentKeyResult", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadKeyResult(oid);
                                checkWeight("departmentKeyResult/checkWeight", data);
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }

            /*删除部门关键结果*/
            function deleteResult() {
                let id = keyResultGrid.getSelectedRowId();
                if (id == null) {
                    dhtmlx.alert("请选中您将要删除的关键结果");
                    return;
                }
                dhtmlx.confirm('主人，真的要狠心删除我吗', function (result) {
                    if (result) {
                        let data = "id=" + id;
                        dhx.ajax.post("departmentKeyResult/deleteDepartmentKeyResultById", data, function () {
                            keyResultGrid.deleteRow(id);
                        });
                    } else {
                        dhtmlx.alert("已取消删除");
                    }
                });
            }

            /*编辑部门关键结果*/
            function editResult() {
                let kid = keyResultGrid.getSelectedRowId();
                let oid = objectGrid.getSelectedRowId();
                if (kid == null) {
                    dhtmlx.alert("请选中您将要编辑的关键结果");
                    return;
                }

                let formData = [
                    {
                        type: "checkbox", checked: true, list: [
                            {type: "settings", labelWidth: 90, inputWidth: 200, position: "label-left"},
                            {
                                type: "input",
                                name: "keyResultName",
                                label: "关键结果名",
                                value: keyResultGrid.cells(kid, 2).getValue()
                            },
                            {
                                type: "input",
                                name: "weight",
                                label: "权重",
                                value: keyResultGrid.cells(kid, 3).getValue(),
                                validate: "^\\d+(\\.\\d+)?$",
                                required: true
                            }
                        ]
                    },
                    {
                        type: "checkbox", checked: 1, name: "check", list: [
                            {type: "button", name: "OK", value: "确认", offsetLeft: 40, offsetTop: 10, inputWidth: 50},
                            {type: "newcolumn"},
                            {type: "button", name: "CANCEL", value: "取消", offsetLeft: 8, offsetTop: 10}
                        ]
                    }
                ];
                let dhxWins = new dhtmlXWindows();
                dhxWins.attachViewportTo("my_tabBar");
                let w1 = dhxWins.createWindow("w1", "0", "0", "300", "280");
                dhxWins.window("w1").center();
                w1.setText("编辑关键结果");
                let myForm = w1.attachForm(formData);
                myForm.enableLiveValidation(true);
                myForm.attachEvent("onValidateError", function (name, value, result) {
                    dhtmlx.alert(myForm.getItemLabel(name) + ": 错误");
                    myForm.uncheckItem("check");
                });
                myForm.attachEvent("onValidateSuccess", function (name, value, result) {
                    if (parseFloat(myForm.getItemValue("weight")) > 100) {
                        dhtmlx.alert(myForm.getItemLabel("weight") + ": 错误大于了100");
                        myForm.uncheckItem("check");
                        return;
                    }
                    myForm.checkItem("check");
                });
                myForm.attachEvent("onButtonClick", function (name) {
                    if (name === "OK") {
                        let data = "keyResultName=" + encodeURI(encodeURI(myForm.getItemValue("keyResultName"))) +
                            "&weight=" + encodeURI(encodeURI(myForm.getItemValue("weight"))) + "&keyResultId=" + kid;
                        let data1 = "objectId=" + oid;
                        dhx.ajax.post("departmentKeyResult/updateDepartmentKeyResult", data, function (result) {
                            if (result.xmlDoc.responseText === "true") {
                                loadKeyResult(oid);
                                checkWeight("departmentKeyResult/checkWeight", data1);
                            }
                        });
                    }
                    dhxWins.window("w1").hide();
                });
            }
        }
    </script>
</head>
<body onload="doOnLoad();">
<div id="my_tabBar" style="width: 100%; height:100%;"></div>
</body>
</html>