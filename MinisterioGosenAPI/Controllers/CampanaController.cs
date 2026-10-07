using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CampanaController(
        IConfiguration _config) : ControllerBase
    {
        // =========================================================
        // PLANTILLAS
        // =========================================================

        [HttpGet("ListarPlantillasCampanaAPI")]
        public IActionResult ListarPlantillasCampanaAPI()
        {
            using var context =
                new NpgsqlConnection(
                    _config["ConnectionStrings:DefaultConnection"]
                );

            var response =
                context.Query<CampanaPlantillaResponseModel>(
                    "SELECT * FROM spListarPlantillasCampana()"
                ).ToList();

            return Ok(response);
        }
    }
}