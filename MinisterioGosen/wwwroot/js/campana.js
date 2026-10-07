document.addEventListener("DOMContentLoaded", function () {

    const form = document.getElementById("formCampana");

    if (!form) {
        return;
    }


    // =========================================================
    // ELEMENTOS
    // =========================================================

    const titulo =
        document.getElementById("Titulo");

    const asunto =
        document.getElementById("Asunto");

    const contenido =
        document.getElementById("Contenido");

    const todos =
        document.getElementById("Todos");

    const opcionTodos =
        document.getElementById("opcionTodos");

    const filtros =
        document.getElementById("contenedorFiltrosDestinatarios");

    const destinatarios =
        document.querySelectorAll(".destinatario-check");

    const roles =
        document.querySelectorAll(".rol-check");

    const ministerios =
        document.querySelectorAll(".ministerio-check");

    const plantillas =
        document.querySelectorAll(".plantilla-option");

    const resumen =
        document.getElementById("resumenDestinatarios");

    const mensajeValidacion =
        document.getElementById("mensajeValidacion");

    const textoValidacion =
        document.getElementById("textoValidacion");


    // Vista previa
    const previewTitulo =
        document.getElementById("previewTitulo");

    const previewAsunto =
        document.getElementById("previewAsunto");

    const previewContenido =
        document.getElementById("previewContenido");

    const previewHeader =
        document.getElementById("previewHeader");


    // Contadores
    const contadorTitulo =
        document.getElementById("contadorTitulo");

    const contadorAsunto =
        document.getElementById("contadorAsunto");


    // =========================================================
    // VISTA PREVIA
    // =========================================================

    function actualizarPreview() {

        previewTitulo.textContent =
            titulo.value.trim() ||
            "Título de la campaña";

        previewAsunto.textContent =
            asunto.value.trim() ||
            "Asunto del correo";

        previewContenido.textContent =
            contenido.value.trim() ||
            "El contenido de la campaña aparecerá aquí.";

    }


    function actualizarContadores() {

        contadorTitulo.textContent =
            titulo.value.length;

        contadorAsunto.textContent =
            asunto.value.length;

    }


    titulo.addEventListener(
        "input",
        function () {

            actualizarPreview();
            actualizarContadores();

        }
    );


    asunto.addEventListener(
        "input",
        function () {

            actualizarPreview();
            actualizarContadores();

        }
    );


    contenido.addEventListener(
        "input",
        actualizarPreview
    );


    // =========================================================
    // PLANTILLAS
    // =========================================================

    function actualizarPlantilla() {

        const seleccionada =
            document.querySelector(
                ".plantilla-option:checked"
            );

        if (!seleccionada) {
            return;
        }


        previewHeader.classList.remove(
            "plantilla-general",
            "plantilla-informativa",
            "plantilla-recordatorio"
        );


        switch (seleccionada.value) {

            case "Informativa":

                previewHeader.classList.add(
                    "plantilla-informativa"
                );

                break;


            case "Recordatorio":

                previewHeader.classList.add(
                    "plantilla-recordatorio"
                );

                break;


            default:

                previewHeader.classList.add(
                    "plantilla-general"
                );

                break;

        }

    }


    plantillas.forEach(function (plantilla) {

        plantilla.addEventListener(
            "change",
            actualizarPlantilla
        );

    });


    // =========================================================
    // MARCAR VISUALMENTE CHECKBOXES
    // =========================================================

    function actualizarClasesDestinatarios() {

        destinatarios.forEach(function (checkbox) {

            const contenedor =
                checkbox.closest(
                    ".destinatario-option"
                );

            if (!contenedor) {
                return;
            }


            contenedor.classList.toggle(
                "seleccionado",
                checkbox.checked
            );

        });


        if (opcionTodos) {

            opcionTodos.classList.toggle(
                "seleccionado",
                todos.checked
            );

        }

    }


    // =========================================================
    // DESTINATARIOS
    // =========================================================

    function actualizarDestinatarios() {

        if (todos.checked) {

            filtros.classList.add(
                "campana-filtros-deshabilitados"
            );

            filtros.style.opacity = "0.45";


            destinatarios.forEach(function (checkbox) {

                checkbox.checked = false;
                checkbox.disabled = true;

            });


            resumen.textContent =
                "La campaña será enviada a todos los usuarios activos.";


            actualizarClasesDestinatarios();

            return;
        }


        filtros.classList.remove(
            "campana-filtros-deshabilitados"
        );

        filtros.style.opacity = "1";


        destinatarios.forEach(function (checkbox) {

            checkbox.disabled = false;

        });


        const rolesSeleccionados =
            document.querySelectorAll(
                ".rol-check:checked"
            ).length;


        const ministeriosSeleccionados =
            document.querySelectorAll(
                ".ministerio-check:checked"
            ).length;


        if (
            rolesSeleccionados === 0 &&
            ministeriosSeleccionados === 0
        ) {

            resumen.textContent =
                'Seleccione al menos un rol, ministerio o la opción "Todos".';


            actualizarClasesDestinatarios();

            return;
        }


        const partes = [];


        if (rolesSeleccionados > 0) {

            partes.push(
                rolesSeleccionados +
                (
                    rolesSeleccionados === 1
                        ? " rol seleccionado"
                        : " roles seleccionados"
                )
            );

        }


        if (ministeriosSeleccionados > 0) {

            partes.push(
                ministeriosSeleccionados +
                (
                    ministeriosSeleccionados === 1
                        ? " ministerio seleccionado"
                        : " ministerios seleccionados"
                )
            );

        }


        resumen.textContent =
            "La lista de distribución se generará utilizando " +
            partes.join(" y ") +
            ".";


        actualizarClasesDestinatarios();

    }


    todos.addEventListener(
        "change",
        actualizarDestinatarios
    );


    destinatarios.forEach(function (checkbox) {

        checkbox.addEventListener(
            "change",
            actualizarDestinatarios
        );

    });


    // =========================================================
    // VALIDACIÓN
    // =========================================================

    function limpiarValidacion() {

        mensajeValidacion.classList.add(
            "d-none"
        );


        titulo.classList.remove(
            "is-invalid"
        );

        asunto.classList.remove(
            "is-invalid"
        );

        contenido.classList.remove(
            "is-invalid"
        );

    }


    function mostrarError(mensaje) {

        textoValidacion.textContent =
            mensaje;

        mensajeValidacion.classList.remove(
            "d-none"
        );


        mensajeValidacion.scrollIntoView({
            behavior: "smooth",
            block: "center"
        });

    }


    form.addEventListener(
        "submit",
        function (event) {

            limpiarValidacion();


            // Título
            if (!titulo.value.trim()) {

                event.preventDefault();

                titulo.classList.add(
                    "is-invalid"
                );

                mostrarError(
                    "Debe ingresar el título de la campaña."
                );

                titulo.focus();

                return;

            }


            // Asunto
            if (!asunto.value.trim()) {

                event.preventDefault();

                asunto.classList.add(
                    "is-invalid"
                );

                mostrarError(
                    "Debe ingresar el asunto del correo."
                );

                asunto.focus();

                return;

            }


            // Contenido
            if (!contenido.value.trim()) {

                event.preventDefault();

                contenido.classList.add(
                    "is-invalid"
                );

                mostrarError(
                    "Debe ingresar el contenido de la campaña."
                );

                contenido.focus();

                return;

            }


            // Plantilla
            const plantillaSeleccionada =
                document.querySelector(
                    ".plantilla-option:checked"
                );


            if (!plantillaSeleccionada) {

                event.preventDefault();

                mostrarError(
                    "Debe seleccionar una plantilla para la campaña."
                );

                return;

            }


            // Destinatarios
            const algunoSeleccionado =
                document.querySelectorAll(
                    ".destinatario-check:checked"
                ).length > 0;


            if (
                !todos.checked &&
                !algunoSeleccionado
            ) {

                event.preventDefault();

                mostrarError(
                    'Debe seleccionar al menos un rol, un ministerio o la opción "Todos".'
                );

                return;

            }

        }
    );


    // =========================================================
    // INICIALIZACIÓN
    // =========================================================

    actualizarPreview();
    actualizarContadores();
    actualizarPlantilla();
    actualizarDestinatarios();

});