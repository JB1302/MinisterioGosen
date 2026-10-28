using System.ComponentModel.DataAnnotations;

namespace MinisterioGosenAPI.Models
{
    public class CampanaCrearRequestModel
    {
        [Required]
        public string Titulo { get; set; } = string.Empty;


        [Required]
        public string Asunto { get; set; } = string.Empty;


        [Required]
        public string Contenido { get; set; } = string.Empty;


        [Required]
        public string Plantilla { get; set; } = string.Empty;


        [Required]
        public int Id_Usuario_Creador { get; set; }


        public List<int> Ids_Roles { get; set; } = [];


        public List<int> Ids_Ministerios { get; set; } = [];


        public bool Todos { get; set; }
    }
}